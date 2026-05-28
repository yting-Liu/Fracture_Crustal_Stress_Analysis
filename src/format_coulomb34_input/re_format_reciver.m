
%% convert corrdinates

%input_file = 'fractures.txt';
input_file = 'p53-1.txt';
tmp_file = 'll2utm.txt'
%output_file = 'reciver_fault.inr';
output_file = 'p-1.inr';
fid_in = fopen(input_file, 'r');
fid_tmp = fopen(tmp_file,'w');

if fid_in == -1
    error('Error opening input file.');
end

while ~feof(fid_in)
    line = fgetl(fid_in);    
    % Check if the line is a header (starts with "> -L")
    if startsWith(line, '> -L')
        fprintf(fid_tmp, '%s\n', line);        
    elseif ~isempty(line)
        % Process coordinate lines
        coords = sscanf(line, '%f %f'); % Read longitude and latitude
        lon = coords(1);
        lat = coords(2);
        xy = lonlat2xy([lon,lat]);  

        fprintf(fid_tmp, '%.5f\t%.5f\n', xy(1), xy(2));
        
    end
end
fclose(fid_in);

%% rewrite format
fid_tmp = fopen(tmp_file, 'r');
fid_out = fopen(output_file, 'w')

lines = {};
while ~feof(fid_tmp)
    lines{end+1} = fgetl(fid_tmp);
end
fclose(fid_tmp);

block_id = 0;
coordinates = [];

for i = 1:length(lines)
    line = lines{i};
    
    if startsWith(line, '> -L')
        block_id = sscanf(line, '> -L"%d"');
        coordinates = []; 
        
        j = i + 1;
        while j <= length(lines) && ~startsWith(lines{j}, '> -L') && ~isempty(lines{j})
            coords = sscanf(lines{j}, '%f %f');
            coordinates = [coordinates; coords']; 
            j = j + 1;
        end
        
        for k = 1:size(coordinates, 1) - 1
            x1 = coordinates(k, 1);
            y1 = coordinates(k, 2); 
            x2 = coordinates(k + 1, 1);
            y2 = coordinates(k + 1, 2);
            
            output_data = [2, x1, y1, x2, y2, 100, -90, 0, 90, 0, 5];
            fprintf(fid_out, '%d %10.5f %10.5f %10.5f %10.5f %d %10.5f %10.5f %d %10.5f %10.5f reciver%d\n', output_data, block_id);
        end
    end
end
fclose(fid_out);
