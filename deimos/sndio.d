module deimos.sndio;

extern (C) nothrow:

/+
 + default audio device and MIDI port
 +/
enum SIO_DEVANY = "default";
enum MIO_PORTANY = "default";

/+
 + limits
 +/
enum SIOCTL_NAMEMAX = 12;       /// max name length

/+
 + private ``handle'' structure
 +/
struct sio_hdl;
struct mio_hdl;
struct sioctl_hdl;

/+
 + parameters of a full-duplex stream
 +/
struct sio_par {
    uint bits;                  /// bits per sample
    uint bps;                   /// bytes per sample
    uint sig;                   /// 1 = signed, 0 = unsigned
    uint le;                    /// 1 = LE, 0 = BE byte order
    uint msb;                   /// 1 = MSB, 0 = LSB aligned
    uint rchan;                 /// number channels for recording direction
    uint pchan;                 /// number channels for playback direction
    uint rate;                  /// frames per second
    uint bufsz;                 /// end-to-end buffer size
enum SIO_IGNORE = 0;            /// pause during xrun
enum SIO_SYNC = 1;              /// resync after xrun
enum SIO_ERROR = 2;             /// terminate on xrun
    uint xrun;                  /// what to do on overruns/underruns
    uint round;                 /// optimal bufsz divisor
    uint appbufsz;              /// minimum buffer size
    int[3] __pad;               /// for future use
    uint __magic;               /// for internal/debug purposes only
};

/+
 + capabilities of a stream
 +/
struct sio_cap {
enum SIO_NENC = 8;
enum SIO_NCHAN = 8;
enum SIO_NRATE = 16;
enum SIO_NCONF = 4;
    struct sio_enc {            /// allowed sample encodings
        uint bits;
        uint bps;
        uint sig;
        uint le;
        uint msb;
    };
    sio_enc[SIO_NENC] enc;
    uint[SIO_NCHAN] rchan;      /// allowed values for rchan
    uint[SIO_NCHAN] pchan;      /// allowed values for pchan
    uint[SIO_NRATE] rate;       /// allowed rates
    int[7] __pad;               /// for future use
    uint nconf;                 /// number of elements in confs[]
    struct sio_conf {
        uint enc;               /// mask of enc[] indexes
        uint rchan;             /// mask of chan[] indexes (rec)
        uint pchan;             /// mask of chan[] indexes (play)
        uint rate;              /// mask of rate[] indexes
    };
    sio_conf[SIO_NCONF] confs;
};

enum SIO_XSTRINGS : string { ignore = "ignore", sync = "sync", error = "error" };

/+
 + controlled component of the device
 +/
struct sioctl_node {
    char[SIOCTL_NAMEMAX] name;  /// ex. "spkr"
    int unit;                   /// optional number or -1
};

/+
 + description of a control (index, value) pair
 +/
struct sioctl_desc {
    uint addr;                  /// control address
enum SIOCTL_NONE = 0;           /// deleted
enum SIOCTL_NUM = 2;            /// integer in the 0..maxval range
enum SIOCTL_SW = 3;             /// on/off switch (0 or 1)
enum SIOCTL_VEC = 4;            /// number, element of vector
enum SIOCTL_LIST = 5;           /// switch, element of a list
enum SIOCTL_SEL = 6;            /// element of a selector
    uint type;                  /// one of above
    char[SIOCTL_NAMEMAX] func;  /// function name, ex. "level"
    char[SIOCTL_NAMEMAX] group; /// group this control belongs to
    sioctl_node node0;          /// affected node
    sioctl_node node1;          /// ditto for SIOCTL_{VEC,LIST,SEL}
    uint maxval;                /// max value
    int[3] __pad;
};

/+
 + mode bitmap
 +/
enum SIO_PLAY = 1;
enum SIO_REC = 2;
enum MIO_OUT = 4;
enum MIO_IN = 8;
enum SIOCTL_READ = 0x100;
enum SIOCTL_WRITE = 0x200;

/+
 + default bytes per sample for the given bits per sample
 +/
enum SIO_BPS(bits) = (((bits) <= 8) ? 1 : (((bits) <= 16) ? 2 : 4));

/+
 + default value of "sio_par->le" flag
 +/
version (LittleEndian)
{
    enum SIO_LE_NATIVE = 1;
}
else
{
    enum SIO_LE_NATIVE = 0;
}

/+
 + maximum value of volume, eg. for sio_setvol()
 +/
enum SIO_MAXVOL = 127;

struct pollfd;

void sio_initpar(sio_par*);
sio_hdl* sio_open(const scope char*, uint, int);
void sio_close(sio_hdl*);
int sio_setpar(sio_hdl*, sio_par*);
int sio_getpar(sio_hdl*, sio_par*);
int sio_getcap(sio_hdl*, sio_cap*);
void sio_onmove(sio_hdl*, void function(void*, int), void*);
size_t sio_write(sio_hdl*, const void*, size_t);
size_t sio_read(sio_hdl*, void*, size_t);
int sio_start(sio_hdl*);
int sio_stop(sio_hdl*);
int sio_nfds(sio_hdl*);
int sio_pollfd(sio_hdl*, pollfd*, int);
int sio_revents(sio_hdl*, pollfd*);
int sio_eof(sio_hdl*);
int sio_setvol(sio_hdl*, uint);
int sio_onvol(sio_hdl*, void function(void*, uint), void*);

mio_hdl* mio_open(const scope char*, uint, int);
void mio_close(mio_hdl*);
size_t mio_write(mio_hdl*, const void*, size_t);
size_t mio_read(mio_hdl*, void*, size_t);
int mio_nfds(mio_hdl*);
int mio_pollfd(mio_hdl*, pollfd*, int);
int mio_revents(mio_hdl*, pollfd*);
int mio_eof(mio_hdl*);

sioctl_hdl* sioctl_open(const char*, uint, int);
void sioctl_close(sioctl_hdl*);
int sioctl_ondesc(sioctl_hdl*,
    void function(void*, sioctl_desc*, int), void*);
int sioctl_onval(sioctl_hdl*,
    void function(void*, uint, uint), void*);
int sioctl_setval(sioctl_hdl*, uint, uint);
int sioctl_nfds(sioctl_hdl*);
int sioctl_pollfd(sioctl_hdl*, pollfd*, int);
int sioctl_revents(sioctl_hdl*, pollfd*);
int sioctl_eof(sioctl_hdl*);

int mio_rmidi_getfd(const scope char*, uint, int);
mio_hdl* mio_rmidi_fdopen(int, uint, int);
int sio_sun_getfd(const scope char*, uint, int);
sio_hdl* sio_sun_fdopen(int, uint, int);
int sioctl_sun_getfd(const char *, uint, int);
sioctl_hdl* sioctl_sun_fdopen(int, uint, int);
