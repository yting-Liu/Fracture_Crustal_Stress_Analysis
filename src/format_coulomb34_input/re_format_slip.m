% for faults with left-lateral and normal slip
%%
    a = load('slip.inv'); % coseismic slip
    id = a(:,2);    
    ip = a(:,3);

    b = [];
    for i=1:1:max(id)
        for j=1:max(ip)  
            b = [b;a(a(:,2) == i & a(:,3) == j,:)];
        end
    end

    L = b(:,7);
    W = b(:,8);
    dip_angle = b(:,9);
    dip = b(:,9)/180*pi;
    strike = b(:,10)/180*pi;
    ss = -1*b(:,11); 
    ds = b(:,12);

    xs = b(:,4);
    ys = b(:,5);
    zs = b(:,6);

    c = zeros(4, 3, length(dip));
    for j = 1:length(dip)
        tx = [xs(j) , xs(j) + L(j)*sin(strike(j));
            xs(j) + W(j)*cos(dip(j))*cos(strike(j)), xs(j) + L(j)*sin(strike(j)) + W(j)*cos(dip(j))*cos(strike(j))];
        ty = [ys(j) , ys(j) + L(j)*cos(strike(j)) ;
            ys(j) - W(j)*cos(dip(j))*sin(strike(j)), ys(j) + L(j)*cos(strike(j)) - W(j)*cos(dip(j))*sin(strike(j))];
        tz = [zs(j) , zs(j);
            zs(j) - W(j)*sin(dip(j)), zs(j) - W(j)*sin(dip(j))];
        c(:,:,j) = [tx(:), ty(:), tz(:)];
    end

    d = [];
    [rake netslip] = comp2rake(ss,ds);
    [xo,yo] = utm2ll(-117.85,38.169,0,1);
    for k = 1:1:length(ss)
        [lon_start,lat_start] = utm2ll(c(1,1,k)+xo,c(1,2,k)+yo,11,2);
        [lon_fin,lat_fin] = utm2ll(c(3,1,k)+xo,c(3,2,k)+yo,11,2);
        start = lonlat2xy([lon_start lat_start]);
        fin = lonlat2xy([lon_fin lat_fin]);
        top = -1*c(1,3,k)/1000;
        bot = -1*c(2,3,k)/1000;

        d = [d;1,start(1),start(2),fin(1),fin(2),100,rake(k),netslip(k)/100,dip_angle(k),top,bot];
    end

    d(d(:,7) == 90,7) = -90; %noramal
    d(isnan(d(:,7)),7) = 0; %left

    fileID = fopen('source_fault.inr', 'w');
    for i = 1:size(d,1)
        fprintf(fileID, '%d %10.5f %10.5f %10.5f %10.5f %d %10.5f %10.5f %d %10.5f %10.5f %s\n', d(i,:),'source');
    end
    fclose(fileID);

    



