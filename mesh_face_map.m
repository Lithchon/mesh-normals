clc
clear all

nodes = dlmread("nlist_airfoil.txt");
nodes(:,1) = [];
elements = dlmread("elist_airfoil.txt");
elements(:,1:6) = [];
hexmap  = [1 2 3 4; 1 2 6 5; 2 3 7 6; 3 7 8 4; 1 4 8 5; 5 6 7 8];
given_node = 264;
area_nodes = dlmread("area_list.txt");
area_nodes(:,2:end)  = [];


count = length(elements);
faces = zeros(count*6, 4);
for i = 1:count
    the_element = elements(i,:);
    faces(6*(i-1)+1:6*i,:) = the_element(hexmap);
end
faces = unique(faces,'row'); % sort out duplicate faces
faces(any(~ismember(faces, area_nodes),2),:) = []; % sort out inner faces
faces = remove_collapsed_faces(faces); % remove collapsed faces(line, point)

face_map = face_lines(faces(1, :)); 
faces(1,:) = [];

while true
    %first look at the top face
    top_face = face_map(1:2,:);
    [found_face, faces] = top_face_finder(faces, top_face);
    
    if ~isempty(found_face)
        face_map = [found_face; face_map];
    else
        break
    end
end
row_count = size(face_map, 1);
while true
    %then look at the bottom face
    bottom_face = face_map(row_count-1:row_count,:);
    [found_face, faces] = top_face_finder(faces, bottom_face);
    if ~isempty(found_face)
        face_map = [face_map; found_face];
    else
        break
    end
    row_count = row_count + 1;
end
    col_count = 2;
while true
    %then look at the right face
    temp_col = zeros(row_count,1);
    for i = 2:row_count
        current_face = face_map(i-1:i,col_count-1:col_count);
        [found_face, faces] = right_face_finder(faces, current_face);
        if ~isempty(found_face)
            temp_col(i-1:i) = found_face;
        else
            break
        end
    end
    if temp_col == 0
        break
    else
        face_map = [face_map, temp_col];
        col_count = col_count + 1;
    end
end

while true
    %then look at the left face
    temp_col = zeros(row_count,1);
    for i = 2:row_count
        current_face = face_map(i-1:i,1:2);
        [found_face, faces] = left_face_finder(faces, current_face);
        if ~isempty(found_face)
            temp_col(i-1:i) = found_face;
        else
            break
        end
    end
    if temp_col == 0
        break
    else
        face_map = [temp_col, face_map];
    end
end

[x, y, z] = node2coord(face_map, nodes);
%% important

function [X, Y, Z] = node2coord(face_map, nodes)
    
    n = size(face_map, 1);

    X = zeros(size(face_map));
    Y = zeros(size(face_map));
    Z = zeros(size(face_map));
    for i = 1:n
        X(i, :) = nodes(face_map(i, :), 1);
        Y(i, :) = nodes(face_map(i, :), 2);
        Z(i, :) = nodes(face_map(i, :), 3);
    end


end

function [found_face, faces] = top_face_finder(faces, face2check)

    top_line = face2check(1,:);
    % clockwise numbering
    [found_face, faces] = neighbor_finder(faces, top_line);

end

function [found_face, faces] = bot_face_finder(faces, face2check)

    bot_line = face2check(2,:);
    % clockwise numbering
    [found_face, faces] = neighbor_finder(faces, bot_line);

end

function [found_face, faces] = right_face_finder(faces, face2check)

    right_line = face2check(:,2).';
    % clockwise numbering
    [found_face, faces] = neighbor_finder(faces, right_line);
    found_face = found_face.';

end

function [found_face, faces] = left_face_finder(faces, face2check)

    right_line = face2check(:,1).';
    % clockwise numbering
    [found_face, faces] = neighbor_finder(faces, right_line);
    found_face = found_face.';

end

function [found_face, faces] = neighbor_finder(faces, check_line)
    for i = 1:size(faces, 1)
        current_face = [faces(i, :), faces(i, 1)];
        % clockwise_dir
        found_face = finder_helper(current_face, check_line);
        if ~isempty(found_face)
            faces(i,:) = [];
            return
        end
        % counter-clockwise_dir
        current_face = flip(current_face);
        found_face = finder_helper(current_face, check_line);
        if ~isempty(found_face)
            faces(i,:) = [];
            return
        end
    end
    found_face = [];
end

function found_face = finder_helper(face, check_line)

    for j = 1:4
            line_in_q = face(j:j+1);
            if check_line == line_in_q
                if j < 3
                    found_face = [face(j+3), face(j+2)];
                else
                    found_face = [face(j-1), face(j-2)];
                end
                return
            end
    end
    found_face = [];
end

function flist = remove_collapsed_faces(flist)
n_faces = size(flist,1);
    unique_nodes_on_face = zeros(n_faces,1);
    
    for f = 1:n_faces
        
        unique_nodes_on_face(f) = length(unique(flist(f,1:4)));
        
    end
    
    collapsed = [find(unique_nodes_on_face==1); 
    find(unique_nodes_on_face==2)];
    flist(collapsed,:) = [];
end

function [face_node_lines] = face_lines(face)

    dir_1 = [1,2;4,3];

    face_node_lines =   [face(dir_1(1,:)); face(dir_1(2,:))];

end


