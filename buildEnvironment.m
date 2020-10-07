function Environment = buildEnvironment(rows, columns, observations, connected, wrap, self, grid)
    % Initialise Environment structure variables
    Environment = struct;
    Environment.n_locations = rows * columns;

    % Set number of observations
    Environment.n_observations = observations;
    % Now make lists of randomly shuffled observations, in such a way that all observations occur equally often if possible
    locObs = zeros(Environment.n_locations,1);
    for currRepeat = 1:ceil(Environment.n_locations/Environment.n_observations)
        % Randomly shuffle observations
        currObs = randperm(Environment.n_observations);
        % And stick them in the loc_obs vector
        locObs((1+(currRepeat-1)*Environment.n_observations):(min(Environment.n_locations, currRepeat*Environment.n_observations))) = currObs(1:min(Environment.n_observations, Environment.n_locations - (currRepeat-1)*Environment.n_observations));
    end
    
    % Get number of actions
    if rows == 1 || columns == 1 % line
        Environment.n_actions = 2;
    else
        if grid == 1 % square
            Environment.n_actions = 4;
        elseif grid == 2 % triangular
            Environment.n_actions = 6;
        end
    end
    % If self-actions are included: add those to the number of actions too
    if self
        Environment.n_actions = Environment.n_actions + 1;
    end
    
    % Create adjacency matrix first. Adjacency matrix entry i, j = A(i, j) = link from i to j
    if connected
        % If there is only one row or column: don't worry about grid type
        if rows == 1 || columns == 1
            A = tril(circshift(eye(Environment.n_locations),1)) + tril(circshift(eye(Environment.n_locations),1))';
            if wrap
                A(1,Environment.n_locations) = 1;
                A(Environment.n_locations,1) = 1;
            end
        else
            if grid == 1 % square
                if wrap
                    % Regular wrap around rows*columns square graph
                    vecRows = zeros(rows,1);
                    vecRows(2) = 1;
                    vecRows(rows) = 1;
                    vecColumns = zeros(1,columns);
                    vecColumns(2) = 1; 
                    vecColumns(columns) = 1;
                    offdiRows = circulant(vecRows);
                    offdiColumns = circulant(vecColumns);        
                    A = kron(offdiRows,eye(columns)) + kron(eye(rows),offdiColumns);            
                else
                    % Regular hard boundary rows*columns square graph
                    vecRows = zeros(rows,1);
                    vecRows(2) = 1;
                    vecColumns = zeros(1,columns);
                    vecColumns(2) = 1;        
                    offdiRows = toeplitz(vecRows);
                    offdiColumns = toeplitz(vecColumns);        
                    A = kron(offdiRows,eye(columns)) + kron(eye(rows),offdiColumns);
                end
            elseif grid == 2 % triangular
                if wrap
                    % Regular wrap around rows*columns triangular graph
                    diagCols = zeros(1,columns); diagCols(2) = 1; diagCols(columns) = 1;
                    offDiagCols = zeros(1,columns); offDiagCols(2) = 1;
                    oddRows = 1:rows; oddRows = mod(oddRows,2); 
                    diagBlock = toeplitz(diagCols);
                    offDiagUpBlock = eye(columns) + triu(toeplitz(offDiagCols)); offDiagUpBlock(sub2ind(size(offDiagUpBlock),columns,1)) = 1;
                    offDiagDownBlock = eye(columns) + tril(toeplitz(offDiagCols)); offDiagDownBlock(sub2ind(size(offDiagUpBlock),1,columns)) = 1;
                    diagLoc = eye(rows);
                    offDiagDownLoc = triu(circshift(diag(1-oddRows),-1))+triu(circshift(diag(oddRows),-1))'; offDiagDownLoc(1,rows)=1;                
                    offDiagUpLoc = triu(circshift(diag(oddRows),-1))+triu(circshift(diag(1-oddRows),-1))'; offDiagUpLoc(rows,1)=1;
                    A = kron(diagLoc,diagBlock) + kron(offDiagDownLoc,offDiagDownBlock) + kron(offDiagUpLoc,offDiagUpBlock);                
                else
                    % Regular hard boundary rows*columns triangular graph
                    diagCols = zeros(1,columns); diagCols(2) = 1;
                    oddRows = 1:rows; oddRows = mod(oddRows,2); 
                    diagBlock = toeplitz(diagCols);
                    offDiagUpBlock = eye(columns) + triu(toeplitz(diagCols));
                    offDiagDownBlock = eye(columns) + tril(toeplitz(diagCols));
                    diagLoc = eye(rows);
                    offDiagDownLoc = triu(circshift(diag(1-oddRows),-1))+triu(circshift(diag(oddRows),-1))';                
                    offDiagUpLoc = triu(circshift(diag(oddRows),-1))+triu(circshift(diag(1-oddRows),-1))';
                    A = kron(diagLoc,diagBlock) + kron(offDiagDownLoc,offDiagDownBlock) + kron(offDiagUpLoc,offDiagUpBlock);
                end
            end
        end
    else
        A = zeros(Environment.n_locations);
    end 
    % If self-actions included: fill the diagonal of A with ones
    if self
        A(1:(Environment.n_locations + 1):(Environment.n_locations^2)) = 1;
    end
    
    % Now that there is an adjacency matrix: 
    Environment.adjacency = A;
    
    % Define function to convert row and column to ID
    rowColToID = @(r,c) c + (r-1)*columns;
    % Define function to convert ID to row and column
    IDToRowCol = @(ID) [ceil(ID/columns) mod(ID-1, columns)+1];
    % Separate function for just row
    IDToRow = @(ID) ceil(ID/columns);
    % Separate function for just col
    IDToCol = @(ID) mod(ID-1, columns)+1;    
    
    % Store all location properties
    if rows == 1 || columns == 1
        for i = 1:max([rows columns])
            % Set location ID, subtract 1 for python 0-based indexing
            Environment.locations(i).id = i - 1;
            % Set observation for this location
            Environment.locations(i).observation = locObs(i) - 1;
            % Since this is only one line of locations: put them on a ring
            Environment.locations(i).x = 0.5 + 0.3*cos(2*pi*(i/max([rows columns])));
            Environment.locations(i).y = 0.5 + 0.3*sin(2*pi*(i/max([rows columns])));
            % Get all neighbours that can lead to this location, subtract 1 for python 0-based indexing
            Environment.locations(i).in_locations = find(Environment.adjacency(:,i))' - 1;   
            Environment.locations(i).in_degree = sum(Environment.adjacency(:,i));
            % And all neighbours that can be reached from this location, subtract 1 for python 0-based indexing
            Environment.locations(i).out_locations = find(Environment.adjacency(i,:)) - 1;   
            Environment.locations(i).out_degree = sum(Environment.adjacency(i,:));               
        end            
    else
        for i = 1:rows
            for j = 1:columns   
                nodeID = rowColToID(i,j);
                % Set location ID, subtract 1 for python 0-based indexing                                
                Environment.locations(nodeID).id = nodeID - 1;    
                % Set observation for this location
                Environment.locations(nodeID).observation = locObs(nodeID) - 1;                
                % Set location position: x and y according to row and column
                Environment.locations(nodeID).x = (j-(grid==2)*0.5*mod(i,2)-0.5+0.25*(grid==2))/columns;
                Environment.locations(nodeID).y = (i-0.5)/rows;
                % Get all neighbours that can lead to this location, subtract 1 for python 0-based indexing
                Environment.locations(nodeID).in_locations = find(Environment.adjacency(:,nodeID))' - 1;   
                Environment.locations(nodeID).in_degree = sum(Environment.adjacency(:,nodeID));
                % And all neighbours that can be reached from this location, subtract 1 for python 0-based indexing
                Environment.locations(nodeID).out_locations = find(Environment.adjacency(nodeID,:)) - 1;   
                Environment.locations(nodeID).out_degree = sum(Environment.adjacency(nodeID,:));                      
            end
        end
    end
        
    % Set the resulting locations for each action
    if grid == 1
        % Four resulting locations, following angles in unit circle, rescaled by x_sep, y_sep
        pos = [1, 0; 0, 1; -1, 0 ; 0, -1]*[1/columns, 0; 0, 1/rows];
    elseif grid == 2
        % Six resulting locations, following angles in unit circle, rescaled by x_sep, y_sep
        pos = [1, 0; 0.5, 1; -0.5, 1; -1, 0; -0.5, -1; 0.5, -1]*[1/columns, 0; 0, 1/rows];
    end
    % Set the angles for each action, as derived from node positions, which will be used later to find action type
    angles = sort(atan2(pos(:,2), pos(:,1)))+0.01; % Add small offset so I won't have to rely on numerical precision for <=
    
    % Run through all locations to store action properties
    for currLocation = 1:Environment.n_locations
        % Initialise actions for this location
        for currAction = 1:Environment.n_actions
            % Set action id, with -1 for python 0-based indexing
            Environment.locations(currLocation).actions(currAction).id = currAction - 1;
            % Initalise transition: start with this action not leading to any next location
            Environment.locations(currLocation).actions(currAction).transition = zeros(1, Environment.n_locations);
            % Initialise probability: start with zero probability of choosing this action
            Environment.locations(currLocation).actions(currAction).probability = 0;
        end
        % Find all transitions that can be made from this location 
        locationsTo = find(Environment.adjacency(currLocation,:));
        % Run through those transitions to find which action they correspond to
        for currLocTo = locationsTo
            % Initialse current action as empty
            currAction = [];            
            % If the location this transition leads to is self: always use the first action id for this
            if currLocTo == currLocation
                currAction = 1;
            else
                % If this is a single line/ring: the action is simply given by whether you move up or down the line
                if rows == 1 || columns == 1
                    % Check if action this transition correspond to takes you up or down the line
                    currAction = (currLocTo > currLocation);
                    % If this environment wraps: check if this is a wraparound action
                    if wrap
                        % If transition is from first to last or from last to first: wrap around
                        if abs(currLocTo - currLocation) > Environment.n_locations / 2
                            % Flip action for wraparound action
                            currAction = ~currAction;
                        end
                    end
                    % Change the true/false action into an index, and account for self action
                    currAction = currAction + 1 + self;
                else
                    % If this environment wraps around: find direction of this action by using locations on torus                    
                    if wrap
                        % If there are only two rows or only two columns: wraparound is funny, because both 'normal' and 'wraparound' action lead to same location
                        if rows == 2 && IDToRow(currLocation) ~= IDToRow(currLocTo)
                            % If there are two rows, and this is an action that connects the two rows: this is one of those 'double' actions
                            currDir = atan2(mod(Environment.locations(currLocTo).y + 0.75 - Environment.locations(currLocation).y,1) - 0.75, mod(Environment.locations(currLocTo).x + 0.5 - Environment.locations(currLocation).x,1) - 0.5);                        
                            currAction = find(currDir <= angles, 1,'first') + self; 
                            % Now also find the same action in opposite direction. Previously I centered at y=0.75, now I center at y=0.25 (with wraparound) to get the other action
                            currDir = atan2(mod(Environment.locations(currLocTo).y + 0.25 - Environment.locations(currLocation).y,1) - 0.25, mod(Environment.locations(currLocTo).x + 0.5 - Environment.locations(currLocation).x,1) - 0.5);                        
                            currAction = [currAction, find(currDir <= angles, 1,'first') + self];
                            % Since this adds an action to the current location, increase its out-degree by one
                            Environment.locations(currLocation).out_degree = Environment.locations(currLocation).out_degree + 1;
                            % And it creates an action that arrives the current transition location, so increase that in-degree by one 
                            Environment.locations(currLocTo).in_degree = Environment.locations(currLocTo).in_degree + 1;                                 
                        elseif columns == 2 && IDToCol(currLocation) ~= IDToCol(currLocTo) && IDToRow(currLocation) == IDToRow(currLocTo)
                            % If there are two columns, and this is an action that connects the two columns, on the same row: this is one of those 'double' actions
                            currDir = atan2(mod(Environment.locations(currLocTo).y + 0.5 - Environment.locations(currLocation).y,1) - 0.5, mod(Environment.locations(currLocTo).x + 0.75 - Environment.locations(currLocation).x,1) - 0.75);                        
                            currAction = find(currDir <= angles, 1,'first') + self; 
                            % Now also find the same action in opposite direction. Previously I centered at x=0.75, now I center at x=0.25 (with wraparound) to get the other action
                            currDir = atan2(mod(Environment.locations(currLocTo).y + 0.5 - Environment.locations(currLocation).y,1) - 0.5, mod(Environment.locations(currLocTo).x + 0.25 - Environment.locations(currLocation).x,1) - 0.25);                        
                            currAction = [currAction, find(currDir <= angles, 1,'first') + self];   
                            % Since this adds an action to the current location, increase its out-degree by one 
                            Environment.locations(currLocation).out_degree = Environment.locations(currLocation).out_degree + 1;                            
                            % And it creates an action that arrives the current transition location, so increase that in-degree by one 
                            Environment.locations(currLocTo).in_degree = Environment.locations(currLocTo).in_degree + 1;                                                     
                        else
                            % Find which action this transition correponds to from the angle between the current location and the location after transition
                            currDir = atan2(mod(Environment.locations(currLocTo).y + 0.5 - Environment.locations(currLocation).y,1) - 0.5, mod(Environment.locations(currLocTo).x + 0.5 - Environment.locations(currLocation).x,1) - 0.5);                        
                        end
                    else
                        % Find which action this transition correponds to from the angle between the current location and the location after transition
                        currDir = atan2(Environment.locations(currLocTo).y - Environment.locations(currLocation).y, Environment.locations(currLocTo).x - Environment.locations(currLocation).x);
                    end
                    % The action id of this transition is given by the direction bin that this direction falls in
                    if isempty(currAction)
                        currAction = find(currDir <= angles, 1,'first') + self;                      
                    end
                end          
            end
            % Now process the action that was found for this transition - possibly two actions, in the case of wraparound 2 row/column graphs where the same transition can be direct and wraparound
            for a = currAction
                % Now set the transition for the action type that was found
                Environment.locations(currLocation).actions(a).transition(currLocTo) = 1;
                % And set the probability of this action to 1 - it will be normalised afterwards
                Environment.locations(currLocation).actions(a).probability = 1;
            end
        end
        % Update the policy for actions at this location by normalising
        pTot = sum([Environment.locations(currLocation).actions(:).probability]);
        if pTot == 0
            pTot = 1;
        end
        for currAction = 1:Environment.n_actions
            Environment.locations(currLocation).actions(currAction).probability = Environment.locations(currLocation).actions(currAction).probability/pTot;
        end
    end    
end