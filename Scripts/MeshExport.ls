//-----------------------------------------
// LScript - Mesh Export
// Autor: Solokhin Sergey (Neill)

@version 2.3
@script modeler
@warnings
@name Export geometry...

@define     VERSION     100

main
{
    editbegin();

    var totalpolygons[6];
    totalpolygons = polycount();
    
    if (totalpolygons[5] || totalpolygons[6])
    {
        error("In mesh must be only triangles!");
        return;
    }

    ttlPnts = pointcount();
    ttlPlgs = totalpolygons[1];
    if (!ttlPnts)
    {
        error ("<br> You must have geometry!");
        return;
    }

    editend();

    objDir = getdir("Objects");
    if ((ObjPath = getfile("Save Mesh As...", "*.msh", objDir)) == nil)
        return;

    if ((objFile = File(ObjPath, "w")) == nil)
    {
        error("Unable to open file!");
        return;
    }    

    // USER INTERFACE
    reqbegin("Options...");

    var booleans[2];
    booleans[1] = "Yes";
    booleans[2] = "No";
    choice = 1;        // set "Yes" as initial selection

    c1 = ctlchoice("Export polygon normals?",choice,booleans);

    return if !reqpost();

    choice = getvalue(c1);

    reqend();

    objFile.rewind();

    editbegin();

    // prepare progress bar
    ttlSteps = ttlPnts + ttlPlgs;
    if (choice == 1) ttlSteps += ttlPlgs;
    moninit(ttlSteps, "Exporting geometry...");

    // export info
    objFile.writeln("Version: ", VERSION);     

    objFile.writeln("Vertices: ", ttlPnts);
    objFile.writeln("Faces: ", ttlPlgs);

    // export points location in 3d space   
    objFile.writeln("VERTEX_ARRAY");
    for (i=1; i<=ttlPnts; i++)
    {
        pnt = pointinfo( points[i] );
        objFile.writeln(pnt);

        if (monstep())
        {
            editend(ABORT);
            objFile.close;
            return;
        }
    }

    // export polygons indexes
    objFile.writeln("FACE_ARRAY");
    for (i=1; i<=ttlPlgs; i++)
    {
        var pcount = polypointcount( polygons[i] );
        var ppoints[pcount+1]; //acount for surface name [1]
        ppoints = polyinfo( polygons[i] );
                       
        for (x=1; x<=pcount; x++)
        {
            objFile.write(ppoints[x+1], " ");
        }
        objFile.writeln(" ");

        if (monstep())
        {
            editend(ABORT);
            objFile.close;
            return;
        }
    }

    // export polygons normals
    if (choice == 1)
    {
        objFile.writeln("NORMAL_ARRAY");
        for (i=1; i<=ttlPlgs; i++)
        {
            var pnormal = polynormal( polygons[i] );
                           
            objFile.writeln(pnormal);

            if (monstep())
            {
                editend(ABORT);
                objFile.close;
                return;
            }
        }
    }


    monend();
    editend();

    objFile.close();
  

}

