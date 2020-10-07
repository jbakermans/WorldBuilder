function Graph = pythonGraph(matlabGraph)
    % Since I need to define actions types, I will assume a square grid graph
    % Add the option of having self-transitions, where nothing happens
    includeSelf = true;
    
    % Copy number of locations from matlab graph
    Graph.n_locations = matlabGraph.N;
    % Create number of actions
    Graph.n_actions = 4;
    % Add additional action for standing still (transition to self)
    if includeSelf
        Graph.n_actions = Graph.n_actions + 1;
    end
    
    % Run through all locations
    for currLocation = 1:Graph.n_locations
        % Copy ID and x,y location
        Graph.locations(currLocation).id = matlabGraph.nodes(currLocation).id - 1; % -1 for python 0-based indexing
        Graph.locations(currLocation).x = matlabGraph.nodes(currLocation).x;
        Graph.locations(currLocation).y = matlabGraph.nodes(currLocation).y;
        % Create self transition as action 1 if you want to include those
        if includeSelf
            % Self transition is always action 1
            currAction = 1;
            % Store id of this action
            Graph.locations(currLocation).actions(currAction).id = currAction - 1; % -1 for python 0-based indexing
            % And set transition 
            Graph.locations(currLocation).actions(currAction).transition = zeros(1,Graph.n_locations);                        
            Graph.locations(currLocation).actions(currAction).transition(currLocation) = 1;
        end
        % Run through all possible actions
        for currAction = (1+includeSelf):Graph.n_actions
            % Store id of current action
            Graph.locations(currLocation).actions(currAction).id = currAction - 1; % -1 for python 0-based indexing
            % Start with empty transition: this action is not available
            Graph.locations(currLocation).actions(currAction).transition = zeros(1,Graph.n_locations);            
            % Then fill in transitions that can be made from this action
            nodesTo = find(matlabGraph.A(currLocation,:));
            for currNodeTo = nodesTo
                if matlabGraph.nodes(currNodeTo).x > matlabGraph.nodes(currLocation).x && matlabGraph.nodes(currNodeTo).y == matlabGraph.nodes(currLocation).y && currAction == (1+includeSelf)
                    Graph.locations(currLocation).actions(currAction).transition(currNodeTo) = 1;
                end
                if matlabGraph.nodes(currNodeTo).x < matlabGraph.nodes(currLocation).x && matlabGraph.nodes(currNodeTo).y == matlabGraph.nodes(currLocation).y && currAction == (2+includeSelf)
                    Graph.locations(currLocation).actions(currAction).transition(currNodeTo) = 1;
                end
                if matlabGraph.nodes(currNodeTo).x == matlabGraph.nodes(currLocation).x && matlabGraph.nodes(currNodeTo).y > matlabGraph.nodes(currLocation).y && currAction == (3+includeSelf)
                    Graph.locations(currLocation).actions(currAction).transition(currNodeTo) = 1;
                end
                if matlabGraph.nodes(currNodeTo).x == matlabGraph.nodes(currLocation).x && matlabGraph.nodes(currNodeTo).y < matlabGraph.nodes(currLocation).y && currAction == (4+includeSelf)
                    Graph.locations(currLocation).actions(currAction).transition(currNodeTo) = 1;
                end                
            end
        end
    end
end