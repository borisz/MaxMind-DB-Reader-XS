#ifdef __cplusplus
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define NEED_newRV_noinc
#include "ppport.h"
#include "MMDB.h"

#ifdef __cplusplus
}
#endif

static int has_highbyte(const U8 * ptr, int size)
{
    while (--size >= 0)
        if (*ptr++ > 127)
            return 1;
    return 0;
}

/* XXX - this is very gross - but we need to return something that's _not_ a
   binary blob for bigints and this is the easiest way to get that working. */
static SV *decode_bigint(SV * binary) {
    SV * decoded;
    int count;

    dSP;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(binary));
    PUTBACK;
    count = call_pv("MaxMind::DB::Reader::File::XS::_decode_bigint", G_SCALAR);

    SPAGAIN;

    if (count != 1) {
        croak("Called MaxMind::DB::Reader::File::XS::_decode_bigint and got back %i values when we expected 1", count);
    }

    /* The returned SV is mortal, so we need to bump the ref count */
    decoded = newSVsv(POPs);

    PUTBACK;
    FREETMPS;
    LEAVE;

    return decoded;
}

static SV *mksv_r(MMDB_decode_all_s ** current)
{
    SV *sv;
    MMDB_DBG_CARP("type %d\n", (*current)->decode.data.type);

    switch ((*current)->decode.data.type) {
    case MMDB_DTYPE_MAP:
        {
            int key_size;
            const char *key_ptr;
            HV *hv = newHV();
            int size = (*current)->decode.data.data_size;
            SV *val;

            for (*current = (*current)->next; size; size--) {
                assert(*current != NULL);
                assert((*current)->decode.data.type == MMDB_DTYPE_UTF8_STRING
                       || (*current)->decode.data.type == MMDB_DTYPE_BYTES );
                key_size = (*current)->decode.data.data_size;
                key_ptr = size
                    ? (const char *)(*current)->decode.data.ptr
                    : "";
                *current = (*current)->next;
                assert(*current != NULL);
                val = mksv_r(current);
                (void)hv_store(hv, key_ptr, key_size, val, 0);
            }
            sv = newRV_noinc((SV *) hv);
            return sv;
        }
        break;
    case MMDB_DTYPE_ARRAY:
        {
            AV *av = newAV();
            int size = (*current)->decode.data.data_size;
            for (*current = (*current)->next; size; size--) {
                assert(*current != NULL);
                av_push(av, mksv_r(current));
            }
            sv = newRV_noinc((SV *) av);
            return sv;
        }
        break;
    case MMDB_DTYPE_UTF8_STRING:
        {
            int size = (*current)->decode.data.data_size;
            const char *ptr = size
                ? (const char *)(*current)->decode.data.ptr
                : "";
            sv = newSVpvn((const char *)ptr, size);
            if (has_highbyte((const U8*)ptr, size))
                SvUTF8_on(sv);
        }
        break;
    case MMDB_DTYPE_BYTES:
        {
            int size = (*current)->decode.data.data_size;
            sv = newSVpvn( size
                           ? (const char *)(*current)->decode.data.ptr
                           : "", size);
        }
        break;
    case MMDB_DTYPE_IEEE754_FLOAT:
        sv = newSVnv((*current)->decode.data.float_value);
        break;
    case MMDB_DTYPE_IEEE754_DOUBLE:
        sv = newSVnv((*current)->decode.data.double_value);
        break;
    case MMDB_DTYPE_BOOLEAN:
    case MMDB_DTYPE_UINT16:
    case MMDB_DTYPE_UINT32:
        sv = newSVuv((*current)->decode.data.uinteger);
        break;
    case MMDB_DTYPE_UINT64:
        sv = decode_bigint(newSVpvn((const char *)(*current)->decode.data.c8, 8));
        break;
    case MMDB_DTYPE_UINT128:
        sv = decode_bigint(newSVpvn((const char *)(*current)->decode.data.c16, 16));
        break;
    case MMDB_DTYPE_INT32:
        sv = newSViv((*current)->decode.data.sinteger);
        break;
    default:
        assert(0);
    }

    if (*current) {
        *current = (*current)->next;
    }

    return sv;
}

static SV *mksv(MMDB_decode_all_s ** current)
{
    MMDB_decode_all_s *tmp = *current;
    SV *sv = mksv_r(current);
    *current = tmp;
    return sv;
}

static SV *get_mortal_hash_for(MMDB_root_entry_s * root)
{
    SV *sv = &PL_sv_undef;
    if (root->entry.offset > 0) {
        MMDB_decode_all_s *decode_all;
        int status = MMDB_get_tree(&root->entry, &decode_all);
        if (status != MMDB_SUCCESS) {
            croak("MaxMind::DB::Reader::File::XS Err %d", status);
        }
        sv = sv_2mortal(mksv(&decode_all));
        MMDB_free_decode_all(decode_all);
    }
    return sv;
}

static int lookup(MMDB_root_entry_s * root, const char *ipstr, int ai_flags)
{
    struct in_addr ip;
    struct in6_addr ip6;
    int status;
    int depth = root->entry.mmdb->depth;
    if (depth == 32) {
        if (ipstr == NULL || 0 != MMDB_lookupaddressX(ipstr, AF_INET, ai_flags, &ip)) {
            croak("MaxMind::DB::Reader::File::XS Invalid IPv4 Address");
        }
        status = MMDB_lookup_by_ipnum(htonl(ip.s_addr), root);
    } else {
        if (ipstr == NULL || 0 != MMDB_lookupaddressX(ipstr, AF_INET6, ai_flags, &ip6)) {
            croak("MaxMind::DB::Reader::File::XS Invalid IPv6 Address");
        }
        status = MMDB_lookup_by_ipnum_128(ip6, root);
    }
    if (status != MMDB_SUCCESS) {
        croak("MaxMind::DB::Reader::File::XS lookup Err %d", status);
    }
    return status;
}

MODULE = MaxMind::DB::Reader::File::XS    PACKAGE = MaxMind::DB::Reader::File::XS

const char *
lib_version(self)
    CODE:
        RETVAL = MMDB_lib_version();
    OUTPUT:
        RETVAL

MMDB_s *
_open_mmdb(self, file, flags)
    char * file;
    U32 flags;
    PREINIT:
        MMDB_s * mmdb = NULL;
    CODE:
        if ( file == NULL ) {
            croak("MaxMind::DB::Reader::File::XS file missing\n");
        }
        mmdb = MMDB_open(file, flags);
        RETVAL = mmdb;
        if ( mmdb == NULL ) {
            croak("Can't open database %s\n", file );
        }
    OUTPUT:
        RETVAL


void
_close_mmdb(self, mmdb)
        MMDB_s * mmdb;
    CODE:
        MMDB_close(mmdb);


void
_raw_metadata(self, mmdb)
        MMDB_s * mmdb
    PREINIT:
        SV * sv;
        int err;
    PPCODE:
        MMDB_decode_all_s *decode_all = MMDB_alloc_decode_all();
        MMDB_decode_all_s *tmp = decode_all;
        err = MMDB_get_tree(&mmdb->meta, &decode_all);
        if ( err != MMDB_SUCCESS ) {
            croak( "MaxMind::DB::Reader::File::XS Err %d", err );
        }
        sv = mksv(&decode_all);
        MMDB_free_decode_all(tmp);
        XPUSHs(sv_2mortal(sv));

void
_data_for_address(self, mmdb, ipstr)
        MMDB_s * mmdb
        char * ipstr
    PREINIT:
        I32 gV = GIMME_V;
        MMDB_root_entry_s root;
    PPCODE:
        root.entry.mmdb = mmdb;

        lookup(&root, ipstr, AI_NUMERICHOST|AI_V4MAPPED);
        if ( gV != G_VOID ) {
            SV * sv = get_mortal_hash_for(&root);
            XPUSHs(sv);
            if ( gV == G_ARRAY ){
                XPUSHs(sv_2mortal(newSVuv(root.netmask)));
            }
        }

