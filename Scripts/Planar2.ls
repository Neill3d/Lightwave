//-----------------------------------------
// LScript Modeler template
//

@version 2.2
@warnings
@script modeler

//@insert "Common.ls"

library "Common.lib";

// global values go here

main
{
    //-- activate selection mode
    selmode(USER);

    editbegin();

    (total) = polycount();
    if (total < 1) {
        error ("You must select some polygons...");
        return;
    }

    cent = center( boundingbox() );

    norm = polynormal( polygons[1] );
    for (i=1; i<=total; ++i)
        norm = center( polynormal( polygons[i] ), norm);

    offset = dot3d(cent, norm);


    //-- translate selection from polys to points
    selPoints();
    
    editbegin();    

    for (i=1; i<=pointcount(); ++i) {
        posA = pointinfo (points[i]);
        delta = (offset - dot3d(posA, norm)) * norm;

        pointmove( points[i], posA+delta);    
    }

    editend();

}

