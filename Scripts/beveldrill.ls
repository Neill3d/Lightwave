//-----------------------------------------
// Polygon Edit Tools
// Create by Solohin Sergey (Neill)
// BEVEL DRILL OPERATION
//-----------------------------------------
// todo: 1) i see error in bevel last operation. Like invalide second arg
// 2) when i tryed to drill with only single quad, there is didn't happend nothing
//      because it was a error like - too small buffer to perform this operation

@version 2.2
@warnings
@script modeler

// global values go here
@define PLUG_VERSION    0.9

//-- const for classify operation
@define LEFT            1
@define RIGHT           2
@define BEHIND          3
@define BEYOND          4
@define BEETWEN         5
@define ORIGIN          6
@define DESTINATION     7

//-- work plane's
@define XY              1
@define XZ              2
@define YZ              3

main
{

    //-----------------------------------------------------------------------------------------------------\\
    //-----------------------------------------------------------------------------------------------------\\
    //--                                         USER INTERFACE                                          --\\
    //-----------------------------------------------------------------------------------------------------\\
    //-----------------------------------------------------------------------------------------------------\\
    axisVal     = XY;
    offsetVal   = 0.1;

    bevelVal    = 1;    
    insetVal    = 0.5;
    depthVal    = -0.1;

    reqbegin("Bevel Drill operation");
    reqsize(235,240);

    //-- for drill operation
    c1 = ctlchoice("Plane",axisVal,@"XY","XZ","YZ"@);
    ctlposition(c1,43,4);

    c3 = ctlnumber("offset",offsetVal);
    ctlposition(c3,43,28);
    

    //-- for bevel operation
    c4 = ctlchoice("Bevel",bevelVal,@"Yes","No"@);
    ctlposition(c4,43,72);

    c5 = ctlnumber("inset",offsetVal);
    ctlposition(c5,43,96);

    c6 = ctlnumber("depth",depthVal);
    ctlposition(c6,43,120);

    //-- comments
    c2 = ctltext("","Mesh Edit Tools","bevel drill v " + PLUG_VERSION,"Create by Solohin Sergey (Neill)");
    ctlposition(c2,41,146,148,39);

    return if !reqpost();

    //-- return value's
    axisVal     = getvalue(c1);
    offsetVal   = getvalue(c3);

    bevelVal    = getvalue(c4);
    insetVal    = getvalue(c5);
    depthVal    = getvalue(c6);

    reqend();



    //-----------------------------------------------------------------------------------------------------\\
    //-----------------------------------------------------------------------------------------------------\\
    //--                                         PROCESS                                                 --\\
    //-----------------------------------------------------------------------------------------------------\\
    //-----------------------------------------------------------------------------------------------------\\

    //-----------------------------------------------------------------------------------// DRILL OPERATION
    //-- convert curver  into mesh
    freezecurves();

    selmode(USER);

    pntcount = pointcount();
    //info ("points count: ", pntcount );

    //-- array for new points
    var pnts[pntcount];

    count = editbegin();
        
    var n = 1;
    foreach(x, points)
        pnts[n++] = pointinfo(x);
    

    //-- calculate normals and add new points
    //var npnts[pntcount][4] = nil;
    //var npnts[pntcount * 4];    

    var holdp[pntcount];

    var a,b, p1,p2,p3,p4; // points ID
    var pp1, pp2, pp3, pp4; // points position
    
    for (i=1; i<pntcount; i++) 
    {
        a = pnts[i];
        b = pnts[i+1];

        v1 = a-b;

        //-- calc main axis
        var v2 = <0,0,0>;
        switch (axisVal) 
        {
            case YZ: 
                v2 = <1,0,0>;
                v1.x = 0;
                a.x = 0;   
                b.x = 0;
                break;

            case XZ: 
                v2 = <0,1,0>;
                v1.y = 0;
                a.y = 0;   
                b.y = 0;
                break;

            case XY: 
                v2 = <0,0,1>;
                v1.z = 0;
                a.z = 0;   
                b.z = 0;
                break;
        }
        
        //-- calc normalize cross product
        res = normalize(cross3d(v1, v2));

        //-- * offset value
        res = res * offsetVal; 
       
        //-- first points
        var c = <0,0,0>;
        c = res + a;
        pp4 = c;
        p4 = addpoint(c);
        
        //-- add second point
        c = res * -1;
        c = c + a;
        pp3 = c;
        p3 = addpoint(c);
        
        if (i==1) {
            pp1 = pp3;
            p1 = p3;
            pp2 = pp4;
            p2 = p4;
        } else {
            //-- add poly
            var polypnts[4];
            polypnts[1] = p1;
            polypnts[2] = p2;
            polypnts[3] = p4;
            polypnts[4] = p3;
            
            var pntspos[4];
            pntspos[1] = pp1;
            pntspos[2] = pp2;
            pntspos[3] = pp3;
            pntspos[4] = pp4;

            holdp[i - 1] = pntspos;
 
            addpolygon(polypnts);            

            pp1 = pp3;
            p1=p3;
            pp2 = pp4;
            p2=p4;
        }

        //-- last two points, process them
        cnt = pntcount - 1;  
        if (i == cnt) {
            //-- first points
            c = res + b;
            pp4 = c;
            p4 = addpoint(c);
        
            //-- add second point
            c = res * -1;
            c = c + b;
            pp3 = c;
            p3 = addpoint(c);
         
            var polypnts[4];
            polypnts[1] = p1;
            polypnts[2] = p2;
            polypnts[3] = p4;
            polypnts[4] = p3;


            var pntspos[4];
            pntspos[1] = pp1;
            pntspos[2] = pp2;
            pntspos[3] = pp3;
            pntspos[4] = pp4;

            holdp[cnt] = pntspos;            

            addpolygon(polypnts);    
        }

    }   

    //-- clear freeze selected curve
    (count) = polycount();
    for (i=1; i<=count; i++)
        rempoly( polygons[i] );

    editend();

    //-- swap layers, prepare for drill operation
    lyrswap();

    //-- execute template drill operation
    axisdrill(STENCIL, 4 - axisVal, "Mark");

    //-- select new surface
    selpolygon(CLEAR);
    selpolygon(SET, SURFACE, "Mark");
    
    //-- return if use only drill
    return if (bevelVal == 2);

    //-------------------------------------------------------------------------------------------------------
    //-----------------------------------------------------------------------------------// BEVEL OPERATION

    //-- shift selected polygons
    smoothshift(0);
    
    //---------------------------------------------------------------------------- POLYGONS BACKUP
    //-- backUp polygon data
  
    var totalpoints;

    triple();

    (totalpoints) = polycount();

    var shiftPolys[totalpoints];


    //-- create some inset for shift polygons
    //-- shift amout - 50% (I use center function)

    var vertices[4];

    count = editbegin();
    info("count = ", count);


    for (i=1; i<=totalpoints; i++) {
        var pcount = polypointcount( polygons[i] );
        if (pcount > 3) error("Polygon has more than 3 points");
        shiftPolys[i] = polyinfo( polygons[i] );
        shiftPolys[i, 1] = pcount;

        shiftPolys[i, pcount + 2] = polynormal( polygons[i] );
    }

    editend();
    
    //copy();

    undo();

    count = editbegin();    

    var bevelPnts[count];

    //------------------------------------------------------------------------------ INSET SHIFTED POINTS
    //-- transform each new point
    moninit(count, "INSET SHIFTED POINTS...");

    var oldP;
    for (j=1; j<=count; j++) {
        //-- user cancel operation
        if(monstep() )
            break;

        p = round(pointinfo(points[j]), 5);       
        oldP = p;
        
        switch(axisVal) {
            case XY:    z = p.z;
                break;
            case XZ:    z = p.y;
                break;
            case YZ:    z = p.x;
                break;                
        }      

        //-- for all regions
        for (i = 1; i<pntcount; i++) {
            a = pnts[i];
            b = pnts[i+1];
           
            p1 = round(holdp[i,1], 5);
            p2 = round(holdp[i,2], 5);
            p3 = round(holdp[i,3], 5);
            p4 = round(holdp[i,4], 5);

            s1 = classify (p, p1, p2, axisVal);
            s2 = classify (p, p4, p3, axisVal);
            s3 = classify (p, p1, p4, axisVal);
            s4 = classify (p, p2, p3, axisVal);

            //-- left, right twise

            if ( s1>3 || s2>3 || s3>3 || s4>3 )
            {

            } else {

                    p1 = (p1 - p2) * 1.2 + p2;    
                    p2 = (p2 - p1) * 1.2 + p1;
                    p3 = (p3 - p4) * 1.2 + p4;    
                    p4 = (p4 - p3) * 1.2 + p3;

                    vertices[1] = p1;
                    vertices[2] = p2;
                    vertices[3] = p4;
                    vertices[4] = p3;

                    if ( !IsInside(4, vertices, p, axisVal) )
                        continue;
            }
            
            var d = <0,0,0>;
            d = PutPerpendicular(a,b, p, axisVal);

            //-- inset operation (using insetVal)
            //p = center(d,p);
          
            var tempV = d - p;
            tempV.x *= insetVal;
            tempV.y *= insetVal;
            tempV.z *= insetVal;
            p = p + tempV;
       
            //------------------------------------------------------------------------- RESTORE Z COORD
            //-- do trasformation and break loop
            //-- restore z coord
            switch(axisVal) {
                case XY:    p.z = z;
                    break;
                case XZ:    p.y = z;
                    break;
                case YZ:    p.x = z;
                    break;                
            }        
            
            for(ii=1; ii<=totalpoints; ii++) {
                pcount = shiftPolys[ii, 1];
                var verts[pcount];

                var testP = -1;
                for (jj=1; jj<=pcount; jj++) {
                    verts[jj] = round( pointinfo( shiftPolys[ ii, jj + 1 ] ), 5);
                    
                    switch(Axis)
                    {
                        case XY:
                            if (oldP.x == verts[jj].x && oldP.y == verts[jj].y)
                                testP = 1;
                            break;

                        case XZ: 
                            if (oldP.x == verts[jj].x && oldP.z == verts[jj].z)
                                testP = 1;
                            break;

                        case YZ:
                            if (oldP.y == verts[jj].y && oldP.z == verts[jj].z)
                                testP = 1;
                            break;
                    }
  
                    
                }
              
                //-- may be p lays on one of polygon points
                if ( IsInside(3, verts, p, axisVal)   ) {
                    var dir = p;
                    dir[axisVal] -= 10.0;
                    p = projectPointOnPlane (p, dir, verts[1], verts[2], verts[3]);
                    break;
                }
            }
            
            pointmove(points[j], p);  

            //-- bevel points with depth value
            var normal = <0,0,0>;            
            normal = PlaneFromPoints(vertices[1], vertices[2], vertices[3]);
            bevelPnts[j] = p + normal * depthVal;
            

            break;         
        }
    }
    monend();

    editend();

    //-- create bevel depth
    smoothshift(0);

    count = editbegin();
    
    n = 1;
    foreach( x, points )
        pointmove(x, bevelPnts[n++]);

    editend();
       
}
//-----------------------------------------------------------------------------------------------// END
//-----------------------------------------------------------------------------------------------------------




//-----------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------- project Point on plane
//-- orig, dir - projected dir
//-- v0, v1, v2 - plane
projectPointOnPlane: orig, dir, v0, v1, v2
{

    //-- plane attrib's
    var normal = <0,0,0>;
    var dist = 0.0;

    //-- calculate plane value's
    normal = cross3d( (v1 - v0), (v2 - v0) );
    normal = normalize( normal );
    dist = -(normal.x * v0.x) - (normal.y * v0.y) - (normal.z * v0.z);

    //-- variables
    var fRealDist = 0;
    var fCosAngle = 0;

    //-- calculate real distance
    fRealDist = -(dot3d( normal, orig ) + dist);

    var vectRay = normalize(dir - orig);
    fCosAngle = dot3d( normal, vectRay );

    if (fCosAngle == 0)
        return orig;

    fRealDist /= fCosAngle;

    //-- result
    var p = orig + vectRay * fRealDist;
    return p;
}

//-----------------------------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------- plane from points
//-- a,b,c - three points
//-- result - plane
PlaneFromPoints: a, b, c
{
    var plane = <0,0,0>;
    var d1, d2;

    d1 = b-a;
    d2 = c-a;
    plane = cross3d( d2, d1 );
    plane = normalize(plane);

    //plane[3] = DotProduct( a, plane );
    return plane;
}


//-----------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------- function Is point inside polygon
//-- numVertices, vertices - polygon data
//-- p - point for test
//-- use on 2D plane ONLY! (Z coord not used)

IsInside: numVertices, vertices, p, Axis
{
    switch(Axis)
    {
        case XY: return IsInsideXY(numVertices, vertices, p);
            break;

        case XZ: return IsInsideXZ(numVertices, vertices, p);
            break;

        case YZ: return IsInsideYZ(numVertices, vertices, p);
            break;
    }
}

IsInsideXY: numVertices, vertices, p
{ 
    count = 0; // number of ray/edge intersections

    for(i=1; i<=numVertices; i++) {
        j = i % numVertices + 1;
        
        if (vertices[i].y==vertices[j].y)
            continue;
        if (vertices[i].y > p.y && vertices[j].y > p.y)
            continue;
        if (vertices[i].y < p.y && vertices[j].y < p.y)
            continue;
        if ( max(vertices[i].y, vertices[j].y) == p.y )
            count++;
        else
        if ( min(vertices[i].y, vertices[j].y) == p.y)
            continue;
        else
        {
            t = (p.y - vertices[i].y) / (vertices[j].y - vertices[i].y);
            if (vertices[i].x + t * (vertices[j].x - vertices[i].x) >= p.x)
                count++;
        }
    
    }
        
    //-- if (count) point sit. inside polygon
    return (count & 1);
}

IsInsideXZ: numVertices, vertices, p
{ 
    count = 0; // number of ray/edge intersections

    for(i=1; i<=numVertices; i++) {
        j = i % numVertices + 1;
        
        if (vertices[i].z==vertices[j].z)
            continue;
        if (vertices[i].z > p.z && vertices[j].z > p.z)
            continue;
        if (vertices[i].z < p.z && vertices[j].z < p.z)
            continue;
        if ( max(vertices[i].z, vertices[j].z) == p.z )
            count++;
        else
        if ( min(vertices[i].z, vertices[j].z) == p.z)
            continue;
        else
        {
            t = (p.z - vertices[i].z) / (vertices[j].z - vertices[i].z);
            if (vertices[i].x + t * (vertices[j].x - vertices[i].x) >= p.x)
                count++;
        }
    
    }
        
    //-- if (count) point sit. inside polygon
    return (count & 1);
}

IsInsideYZ: numVertices, vertices, p
{ 
    count = 0; // number of ray/edge intersections

    for(i=1; i<=numVertices; i++) {
        j = i % numVertices + 1;
        
        if (vertices[i].z==vertices[j].z)
            continue;
        if (vertices[i].z > p.z && vertices[j].z > p.z)
            continue;
        if (vertices[i].z < p.z && vertices[j].z < p.z)
            continue;
        if ( max(vertices[i].z, vertices[j].z) == p.z )
            count++;
        else
        if ( min(vertices[i].z, vertices[j].z) == p.z)
            continue;
        else
        {
            t = (p.z - vertices[i].z) / (vertices[j].z - vertices[i].z);
            if (vertices[i].y + t * (vertices[j].y - vertices[i].y) >= p.y)
                count++;
        }
    
    }
        
    //-- if (count) point sit. inside polygon
    return (count & 1);
}

//-------------------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------- classify

classify: v, p,q, Axis
{
    switch(Axis)
    {
        case XY: return classifyXY(v, p,q);
            break;

        case XZ: return classifyXZ(v, p,q);
            break;

        case YZ: return classifyYZ(v, p,q);
            break;
    }
}

classifyXY: v,  p,q
{
    a = q - p;
    b = v - p;
    s = a.x * b.y - a.y * b.x;

    if (s > 0)
        return LEFT;
    if (s < 0)
        return RIGHT;
    if (p == v)
        return ORIGIN;
    if (q == v)
        return DESTINATION;
    return BETWEEN;
}

classifyXZ: v,  p,q
{
    a = q - p;
    b = v - p;
    s = a.x * b.z - a.z * b.x;

    if (s > 0)
        return LEFT;
    if (s < 0)
        return RIGHT;
    if (p == v)
        return ORIGIN;
    if (q == v)
        return DESTINATION;
    return BETWEEN;
}

classifyYZ: v,  p,q
{
    a = q - p;
    b = v - p;
    s = a.y * b.z - a.z * b.y;

    if (s > 0)
        return LEFT;
    if (s < 0)
        return RIGHT;
    if (p == v)
        return ORIGIN;
    if (q == v)
        return DESTINATION;
    return BETWEEN;
}

//-----------------------------------------------------------------------------------------------------------
//------------------------------------------------------ function PutPerpendicular from point C to line AB
//-- use on 2D plane ONLY! (Z coord not used)

PutPerpendicular: A,B,C, Axis
{
    switch(Axis)
    {
        case XY: return PutPerpendicularXY(A,B,C);
            break;

        case XZ: return PutPerpendicularXZ(A,B,C);
            break;

        case YZ: return PutPerpendicularYZ(A,B,C);
            break;
    }
}

PutPerpendicularXY: A,B,C
{

    //-- calculate lenght of AB
    l = sqrt( pow(A.x - B.x, 2) + pow(A.y - B.y, 2) );

    //-- parametric P = A + r(B-A)
    r = (A.y - C.y)*(A.y - B.y) - (A.x - C.x)*(B.x - A.x);
    r = r / pow(l, 2);

    P = A + r * (B - A);
    return P;
}

PutPerpendicularXZ: A,B,C
{

    //-- calculate lenght of AB
    l = sqrt( pow(A.x - B.x, 2) + pow(A.z - B.z, 2) );

    //-- parametric P = A + r(B-A)
    r = (A.z - C.z)*(A.z - B.z) - (A.x - C.x)*(B.x - A.x);
    r = r / pow(l, 2);

    P = A + r * (B - A);
    return P;
}

PutPerpendicularYZ: A,B,C
{

    //-- calculate lenght of AB
    l = sqrt( pow(A.y - B.y, 2) + pow(A.z - B.z, 2) );

    //-- parametric P = A + r(B-A)
    r = (A.z - C.z)*(A.z - B.z) - (A.y - C.y)*(B.y - A.y);
    r = r / pow(l, 2);

    P = A + r * (B - A);
    return P;
}






