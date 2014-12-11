//-----------------------------------------
// LScript Angle        by Solokhin Sergey
//      script print angle value between two selected polygons 

@version 2.2
@warnings
@script modeler

// global values go here

main
{
    //-- activate mode for work with visible selection
    selmode(USER);    

    //-- begin edit
    editbegin();

    (total) = polycount();

    if (total <> 2) {
        error ("You must select two polygons: ", total);
        return;
    }

    n1 = polynormal( polygons[1] );
    n2 = polynormal( polygons[2] );

    angle = acos( dot3d(n1,n2) );
    angle = 180 - deg(angle);

    error ("Angle beetwen polygons ", angle );

    //-- finish
    editend();
}

