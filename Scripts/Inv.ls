//---------------------------------------------------------------------------
// LS/IF:  Image Flip                                 by Solokhin Sergey
//
//        flip image data in horisontal or vertical directions
//
// first write 05.03.04
//
// TODO:
// 1. Fix flip for alpha bits in horisontal direction
//---------------------------------------------------------------------------

@version 2.3
@script image

tCtl;

//-- InvKind
//-- 1 - flip horisontal
//-- 2 - flip vertical 
InvKind;

create
{
    InvKind = 1;
    setdesc("Image Flip - by Solokhin Sergey");
}

process: width, height, frame, starttime, endtime
{
    //-- flip horisontal
    if (InvKind == 1) {
        for(i = 1;i <= height;++i)
        {
            red = bufferline(RED,i);
            green = bufferline(GREEN,i);
            blue = bufferline(BLUE,i);
            alpha = bufferline(ALPHA,i);

            halfWidth = integer(width/2);
            for(j = 1;j <= halfWidth;++j)
            {
                invWidth = (width-j+1);

                // flip red bit
                pix             = red[j];
                red[j]          = red[invWidth];
                red[invWidth]   = pix;

                // flip green bit
                pix             = green[j];
                green[j]        = green[invWidth];
                green[invWidth] = pix;

                // flip blue bit
                pix             = blue[j];
                blue[j]         = blue[invWidth];
                blue[invWidth]  = pix;

                // flip alpha bit
                //pix = alpha[j];
                //alpha[j]   = alpha[winvWidth];
                //alpha[invWidth] = pix;
            }

            processrgb(i,red,green,blue,alpha);
        }
    } else {
        //-- flip vertical
        halfHeight = integer(height/2);
        for(i = 1;i <= halfHeight;++i)
        {
            invHeight = (height-i+1);

            Tred = bufferline(RED,i);
            Tgreen = bufferline(GREEN,i);
            Tblue = bufferline(BLUE,i);
            Talpha = bufferline(ALPHA,i);

            red = bufferline(RED,invHeight);
            green = bufferline(GREEN,invHeight);
            blue = bufferline(BLUE,invHeight);
            alpha = bufferline(ALPHA,invHeight);
            
            processrgb(i,red,green,blue,alpha);
            processrgb(invHeight,Tred,Tgreen,Tblue,Talpha);
        }
    }
}

//-----------------------------------------------------------------
// this command is invoked when the user presses the "Options"
// button on the plugin interface

options
{
    reqbegin("Image Flip");

    tCtl = ctlchoice("Flip Type",InvKind,@"Horisontal","Vertical"@);
    ctlposition(tCtl,8,4,220,20);

    return if !reqpost();

    InvKind = getvalue(tCtl);

    reqend();

    if (InvKind == 1) setdesc("Image Flip: horisontal");
    else setdesc("Image Flip: vertical");
}

//-----------------------------------------------------------------
// load() is called when the user loads a scene file where this
// script was active.  the LScript engine will automatically reload
// and recompile this script in such a case.  in load(), we need to
// read in our save()'d operating parameters.

load: what,     // either SCENEMODE (ASCII) or OBJECTMODE (binary)
      io        // a pseudo-FileObject that only supports a subset of the
                     // full FileObject methods
{
    if(what == SCENEMODE)   // processing an ASCII scene file
    {
        line = nil;     // a return of 'nil' can indicate either a
                        // blank line or eof

        while(line == nil && io.eof() != true)
            line = io.read();

        items = parse(" ",line);

        if(items[1] == "FlipDir")
            InvKind = integer(items[2]);

        if (InvKind == 1) setdesc("Image Flip: horisontal");
        else setdesc("Image Flip: vertical");
    }
}

//-----------------------------------------------------------------
// save() is activated when the user saves a scene file where this
// script is active.  in save(), we need to store our operating
// parameters into the scene file.

save: what, io
{
    if(what == SCENEMODE)   // save our working parameters for a later load
        io.writeln("FlipDir ",InvKind);
}
