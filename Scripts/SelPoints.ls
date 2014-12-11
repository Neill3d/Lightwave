//-----------------------------------------
// LScript Modeler template
//

@version 2.2
@warnings
@script modeler

// global values go here

main
{
    var pnts, pntCount=0;
    var total;    

    //-- work with selection
    selmode(DIRECT);

    //-- begin work with mesh
    editbegin(); 
    //-- get count of selected polygons
    (total) = polycount();

    //-- init status monitor
    moninit(total, "Convert selection...");

    //-- set data of point array which we want to select
    for (i=1; i<=total; i++)
        if (!monstep() ) {
            //-- polygon info        
            pcount = polypointcount( polygons[i] );
            
            
            if (!pntCount) {
                pnts = polyinfo( polygons[i] );
                pntCount++;
            } else {
                var parray = polyinfo( polygons[i] );
                pnts += parray;
            }
/*
            //-- for all points in polygon
            for (j=1; j<=pcount; j++) {
                //-- check of this point already exist in array
                Exist = 0;
                for (k=1; k<=pntCount; k++)
                    if (pnts[k] == parray[j+1]) {
                        Exist = 1;
                        break;
                    }

                //-- add point ID to array
                pnts[ ++pntCount ] = parray[j+1]    if (!Exist);
 */     
             
        }
    
    //-- finish edit
    editend();

    //-- close status
    monend();



    //-- clear points selection
    selpoint(CLEAR);
    
    //-- select points according our array
    selpoint(SET, POINTID, pnts); 

}

