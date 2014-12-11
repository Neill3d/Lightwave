//-----------------------------------------
// Clear selection tool
// Autor: Solokhin Sergey

@version 2.2
@warnings
@script modeler
@name Clear selection

main
{
    selmode(USER);      // required for selpoint()/selpolygon()
    selpoint(CLEAR);    // clear any existing selections
    selpolygon(CLEAR);
}

