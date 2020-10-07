function Graph = graphFromAdjacency(A,pos)
    % Initiate variables
    Graph = struct;
    N = size(A,1);
    Graph.N = N;    
    Graph.A = A;
    
    % Get rows and columns; might not look great for generated graphs
    divs = divisors(N);
    rows = divs(ceil(length(divs)/2));
    columns = N/rows;
    % Better: use circle for generated graphs
    phi = linspace(2.5*pi,0.5*pi,N+1); phi = phi(1:N);
    
    % Define function to convert row and column to ID
    rowColToID = @(r,c) c + (r-1)*columns;
    
    for i = 1:rows
        for j = 1:columns            
            nodeID = rowColToID(i,j);
            Graph.nodes(nodeID).id = nodeID;
            if isempty(pos) || size(pos,1) ~= N
                Graph.nodes(nodeID).x = cos(phi(nodeID));
                Graph.nodes(nodeID).y = - sin(phi(nodeID));
            else
                Graph.nodes(nodeID).x = pos(nodeID,1);
                Graph.nodes(nodeID).y = pos(nodeID,2);
            end
            Graph.nodes(nodeID).neighbourIDs = find(A(:,nodeID));   
            Graph.nodes(nodeID).degree = sum(A(:,nodeID));               
        end
    end
end
