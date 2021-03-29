/*
 * Copyright (c) 2021 Benjamin Baier <ben@netzbasis.de>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

import std.stdio;
import std.math;
import std.conv;
import deimos.sndio;

enum SG_SIG = 1;
enum SG_BITS = 16;
enum SG_PCHAN = 2;
enum SG_RATE = 44100;
enum SG_FRAMELEN = SG_BITS / 8 * SG_PCHAN;

static int
fill_sine(short* buf, int bytelen, int hertz)
{
    double rad = 0.0;
    int steps = SG_RATE / hertz;
    double stepwidth = (2 * PI) / steps;
    int pos;

    for (pos = 0; pos * SG_FRAMELEN < bytelen; pos++) {
        short amp = cast(short)(32767 * sin(rad));
        *buf = amp;
        buf++;
        *buf = amp;
        buf++;
        rad += stepwidth;
    }

    for (; pos % steps != 0; pos--) {
    }

    return pos * SG_FRAMELEN;
}

void main(string[] args)
{
    sio_par par;
    short[SG_RATE * SG_PCHAN] buf;

    if (args.length != 3) {
        stderr.writeln("usage: sndio-example [hz] [seconds]");
        return;
    }

    sio_hdl* hdl = sio_open(SIO_DEVANY, SIO_PLAY, 0);
    if (hdl == null) {
        stderr.writeln("sio_open");
        return;
    }

    sio_initpar(&par);
    par.sig = SG_SIG;
    par.bits = SG_BITS;
    par.pchan = SG_PCHAN;
    par.rate = SG_RATE;
    par.le = SIO_LE_NATIVE;

    auto success = sio_setpar(hdl, &par);
    if (success == 0) {
        stderr.writeln("sio_setpar");
        return;
    }

    auto success0 = sio_start(hdl);
    if (success0 == 0) {
        stderr.writeln("sio_start");
        return;
    }

    int hz = to!int(args[1]);
    int size = fill_sine(cast(short*)buf, buf.length, hz);

    for (int i; i < to!int(args[2]) * 2; i++) {
        if (!sio_write(hdl, cast(char*)buf, size))
            break;
    }

    sio_stop(hdl);
    sio_close(hdl);
}
