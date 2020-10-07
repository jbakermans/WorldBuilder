% Jacob Bakermans, November 2017
function WorldBuilder()
    %% STATE VARIABLES

    % Create empty graph struct
    Graph = struct();
    Graph.n_locations = 0;
    Graph.n_observations = 45;    
    Graph.n_actions = 4;
    Graph.locations = [];
    Graph.adjacency = [];
    
    nodesMode = 1; % 1: Add, 2: Remove, 3: Move
    edgesMode = 1; % 1: Add, 2: Remove
    buildMode = 1; % 1: Nodes, 2: Edges, 3: Edit
    graphMode = 1; % 1: Square, 2: Triangular
    
    nodes = []; % Handles of node rectangle objects
    nodesCols = hsv2rgb([(1:Graph.n_observations)'/Graph.n_observations, 0.5 * ones(Graph.n_observations,1), ones(Graph.n_observations,1)]); % List of colours for nodes
    nodesRadius = 0.05; % Radius of node, also sets action sizes (updated when creating graph)
    edges = {}; % Handles of edge patch objects
    edgesCols = hsv2rgb([(1:Graph.n_actions)'/Graph.n_actions, 0.5 * ones(Graph.n_actions,1), ones(Graph.n_actions,1)]); % List of colours for edges
    selectedNode = -1;
    
    %% WINDOW
    % Set window parameters
    bg_color = [0.95 0.95 0.95];
    % determine window size
    screensize = get(0, 'screensize');
    winsize = round([min(1 * screensize(4), 900), min(0.8 * screensize(4), 600)]);
    winoffset = round(0.5 * (screensize(3:4)-winsize));
    % Create window
    window = figure('name', 'Environment Builder', ...
                         'units','pixels', ...
                         'position', [winoffset(:)' winsize(:)'], ...
                         'color', bg_color, ...
                         'menubar', 'none', ... 
                         'numbertitle','off', ...
                         'resize','on');
    set(window, ...
        'DefaultUIPanelBackGroundColor', [0.95 0.95 0.95], ...
        'DefaultUIControlUnits', 'normalized', ...
        'DefaultAxesLooseInset', [0.00, 0, 0, 0], ... 
        'DefaultAxesUnits', 'normalized');
   
    % Set ui size parameters
    pos = getpixelposition(window);
    hp = 4 / pos(3);
    vp = 4 / pos(4);
    graphPanelWidth = 2/3;
    graphPanelHeight = 1;
    buildPanelWidth = 1 - graphPanelWidth;
    buildPanelHeight = 1;
    
    % Create panels
    graphPanel ...
        = uipanel(window, ...
                  'position', [hp, vp, graphPanelWidth - 2*hp, graphPanelHeight - 2*vp], ...
                  'title', 'Graph');
    buildPanel ...
        = uipanel(window, ...
                  'position', [graphPanelWidth+hp, vp, buildPanelWidth - 2*hp, buildPanelHeight - 2*vp], ...
                  'title', 'Build');
    
    % Create axes to draw graph on
    ax = axes('Parent', graphPanel, 'Visible', 'off', 'ButtonDownFcn', @axesCallback, 'PickableParts', 'all'); 
    % Reverse y axis: row number increases from top to bottom
    set(ax,'ydir','reverse');
    % Set axis lims
    xlim(ax, [0 1]);
    ylim(ax, [0 1]);    
    
    %% UI POSITIONS
    % Set positions
    uiWidth = 0.8; % Padding included
    uiHeight = 0.035; % Padding included    
    uiX = (1-uiWidth)/2;
    uiTab = 0.1;
    uiTabWidth = uiWidth-uiTab; % Padding included
    startY = 0.95;
    uiFieldWidth = uiTab * 2; % Padding included
    
    % Set padding for ui
    uihp = hp;
    uivp = 0.5*vp;  
    
    % Set analysis ui vertical space factor
    uivspace = 1.5;
    
    % Graph ui positions
    buildLabelPosition = [(uiX + uihp) startY-uivp (uiWidth-2*uihp) (uiHeight -2*uivp)];   
    buildDimensionsLabelPosition = [(uiX + uiTab + uihp) buildLabelPosition(2)-uiHeight (uiTabWidth-2*uihp) (uiHeight -2*uivp)];    
    buildDimensionsRowsPosition = [(uiX + uiTab + uiTabWidth - 2*uiFieldWidth + uihp) buildLabelPosition(2)-uiHeight (uiFieldWidth-2*uihp) (uiHeight -2*uivp)];    
    buildDimensionsColumnsPosition = [(uiX + uiTab + uiTabWidth - uiFieldWidth + uihp) buildLabelPosition(2)-uiHeight (uiFieldWidth-2*uihp) (uiHeight -2*uivp)];    
    buildSquarePosition = [(uiX + uiTab + uihp) buildDimensionsLabelPosition(2)-uiHeight (uiTabWidth-2*uihp) (uiHeight -2*uivp)];        
    buildTriangularPosition = [(uiX + uiTab + uihp) buildSquarePosition(2)-uiHeight (uiTabWidth-2*uihp) (uiHeight -2*uivp)];                
    buildSetConnectedPosition = [(uiX + uiTab + uihp) buildTriangularPosition(2)-uiHeight (uiTabWidth-2*uihp) (uiHeight -2*uivp)];    
    buildSetWrapPosition = [(uiX + uiTab + uihp) buildSetConnectedPosition(2)-uiHeight (uiTabWidth-2*uihp) (uiHeight -2*uivp)];        
    buildSetSelfPosition = [(uiX + uiTab + uihp) buildSetWrapPosition(2)-uiHeight (uiTabWidth-2*uihp) (uiHeight -2*uivp)];            
    buildButtonPosition = [(uiX + uiTab + uihp) buildSetSelfPosition(2)-uiHeight (uiTabWidth-2*uihp) (uiHeight -2*uivp)];        
    
    nodesLabelPosition = [(uiX + uihp) buildButtonPosition(2)-uiHeight (uiWidth-2*uihp) (uiHeight -2*uivp)];
    nodesObservationsLabelPosition = [(uiX + uiTab + uihp) nodesLabelPosition(2)-uiHeight (uiTabWidth-2*uihp) (uiHeight -2*uivp)];    
    nodesObservationsPosition = [(uiX + uiTab + uiTabWidth - uiFieldWidth + uihp) nodesLabelPosition(2)-uiHeight (uiFieldWidth-2*uihp) (uiHeight -2*uivp)];        
    nodesAddPosition = [(uiX + uiTab + uihp) nodesObservationsPosition(2)-uiHeight (uiTabWidth-2*uihp) (uiHeight -2*uivp)];
    nodesAddObservationPosition = [(uiX + uiTab + uiTabWidth - uiFieldWidth - uihp) nodesObservationsPosition(2)-uiHeight (uiFieldWidth + 2*uihp) (uiHeight -2*uivp)];            
    nodesRemovePosition = [(uiX + uiTab + uihp) nodesAddPosition(2)-uiHeight (uiTabWidth-2*uihp) (uiHeight -2*uivp)];
    nodesMovePosition = [(uiX + uiTab + uihp) nodesRemovePosition(2)-uiHeight (uiTabWidth-2*uihp) (uiHeight -2*uivp)];    
    
    edgesLabelPosition = [(uiX + uihp) nodesMovePosition(2)-uiHeight (uiWidth-2*uihp) (uiHeight -2*uivp)];        
    edgesActionsLabelPosition = [(uiX + uiTab + uihp) edgesLabelPosition(2)-uiHeight (uiTabWidth-2*uihp) (uiHeight -2*uivp)];    
    edgesActionsPosition = [(uiX + uiTab + uiTabWidth - uiFieldWidth + uihp) edgesLabelPosition(2)-uiHeight (uiFieldWidth-2*uihp) (uiHeight -2*uivp)];            
    edgesAddPosition = [(uiX + uiTab + uihp) edgesActionsPosition(2)-uiHeight (uiTabWidth-2*uihp) (uiHeight -2*uivp)];        
    edgesAddActionPosition = [(uiX + uiTab + uiTabWidth - uiFieldWidth - uihp) edgesActionsPosition(2)-uiHeight (uiFieldWidth+2*uihp) (uiHeight -2*uivp)];                
    edgesRemovePosition = [(uiX + uiTab + uihp) edgesAddPosition(2)-uiHeight (uiTabWidth-2*uihp) (uiHeight -2*uivp)];

    editLabelPosition = [(uiX + uihp) edgesRemovePosition(2)-uiHeight (uiWidth-2*uihp) (uiHeight -2*uivp)];        
    
    fileLabelPosition = [(uiX + uihp) editLabelPosition(2)-uiHeight (uiWidth-2*uihp) (uiHeight -2*uivp)];    
    filePosition = [(uiX + uiTab + uihp) fileLabelPosition(2)-uiHeight (uiTabWidth-2*uihp) (uiHeight -2*uivp)];                            
    
    %% GRAPH UI
    buildLabel ...
        = uicontrol(buildPanel, ...
                    'style', 'text', ...
                    'string', 'Build', ...
                    'HorizontalAlignment','left',...
                    'backgroundcolor', bg_color, ...
                    'position', buildLabelPosition);
    buildRadio(1) ...
        = uicontrol(buildPanel, ...
                    'style', 'radiobutton', ...
                    'string', 'Square', ...
                    'value', 1,...      
                    'callback', @buildRadioCallback,...                    
                    'position', buildSquarePosition);  
    buildRadio(2) ...
        = uicontrol(buildPanel, ...
                    'style', 'radiobutton', ...
                    'string', 'Triangular', ...
                    'value', 0,...   
                    'callback', @buildRadioCallback,...                    
                    'position', buildTriangularPosition);                    
    buildDimensionsLabel ...
        = uicontrol(buildPanel, ...
                    'style', 'text', ...
                    'string', 'Dimensions', ...
                    'HorizontalAlignment','left',...    
                    'backgroundcolor', bg_color, ...
                    'position', buildDimensionsLabelPosition);   
    buildDimensionsRows ...
        = uicontrol(buildPanel, ...
                    'style', 'edit', ...
                    'string', '5', ...
                    'callback', @dummyCallback,...  
                    'position', buildDimensionsRowsPosition);     
    buildDimensionsColumns ...
        = uicontrol(buildPanel, ...
                    'style', 'edit', ...
                    'string', '5', ...
                    'callback', @dummyCallback,...  
                    'position', buildDimensionsColumnsPosition);     
    buildSetConnected ...
        = uicontrol(buildPanel, ...
                    'style', 'checkbox', ...
                    'string', 'Connected', ...
                    'value', 1, ...                    
                    'position', buildSetConnectedPosition);              
    buildSetWrap ...
        = uicontrol(buildPanel, ...
                    'style', 'checkbox', ...
                    'string', 'Wrap around', ...
                    'value', 0, ...                    
                    'position', buildSetWrapPosition);  
    buildSetSelf ...
        = uicontrol(buildPanel, ...
                    'style', 'checkbox', ...
                    'string', 'Self-actions', ...
                    'value', 0, ...                    
                    'position', buildSetSelfPosition);                       
    buildButton ...
        = uicontrol(buildPanel, ...
                    'style', 'pushbutton', ...
                    'string', 'Build', ...
                    'TooltipString', 'Build graph',...                      
                    'callback', @buildButtonCallback,...                       
                    'position', buildButtonPosition);       
    nodesRadioLabel ...
        = uicontrol(buildPanel, ...
                    'style', 'radiobutton', ...
                    'string', 'Nodes', ...
                    'enable', 'on',...         
                    'value', 1,...
                    'callback', @modeCallback,...   
                    'position', nodesLabelPosition);  
    nodesObservationsLabel ...
        = uicontrol(buildPanel, ...
                    'style', 'text', ...
                    'string', 'Observations', ...
                    'HorizontalAlignment','left',...    
                    'backgroundcolor', bg_color, ...
                    'position', nodesObservationsLabelPosition);  
    nodesObservations ...
        = uicontrol(buildPanel, ...
                    'style', 'edit', ...
                    'string', num2str(Graph.n_observations), ...
                    'callback', @nodesObservationsCallback,...  
                    'position', nodesObservationsPosition);                     
    nodesRadio(1) ...
        = uicontrol(buildPanel, ...
                    'style', 'radiobutton', ...
                    'string', 'Add', ...
                    'enable', 'on',...         
                    'value', 1,...
                    'callback', @nodesRadioCallback,...                    
                    'position', nodesAddPosition);  
    nodesAddObservation ...
        = uicontrol(buildPanel, ...
                    'style', 'popup', ...
                    'string', '...', ...
                    'enable', 'on',...                    
                    'position', nodesAddObservationPosition);                   
    nodesRadio(2) ...
        = uicontrol(buildPanel, ...
                    'style', 'radiobutton', ...
                    'string', 'Remove', ...
                    'enable', 'on',...                    
                    'value', 0,...
                    'callback', @nodesRadioCallback,...                    
                    'position', nodesRemovePosition);  
    nodesRadio(3) ...
        = uicontrol(buildPanel, ...
                    'style', 'radiobutton', ...
                    'string', 'Move', ...
                    'enable', 'on',...                   
                    'value', 0,... 
                    'callback', @nodesRadioCallback,...                    
                    'position', nodesMovePosition);   
    edgesRadioLabel ...
        = uicontrol(buildPanel, ...
                    'style', 'radiobutton', ...
                    'string', 'Edges', ...
                    'enable', 'on',...         
                    'value', 0,...
                    'callback', @modeCallback,...   
                    'position', edgesLabelPosition);  
    edgesActionLabel ...
        = uicontrol(buildPanel, ...
                    'style', 'text', ...
                    'string', 'Actions', ...
                    'HorizontalAlignment','left',...    
                    'backgroundcolor', bg_color, ...
                    'position', edgesActionsLabelPosition);  
    edgesActions ...
        = uicontrol(buildPanel, ...
                    'style', 'edit', ...
                    'string', num2str(Graph.n_actions), ...
                    'callback', @edgesActionsCallback,...  
                    'position', edgesActionsPosition);                   
    edgesRadio(1) ...
        = uicontrol(buildPanel, ...
                    'style', 'radiobutton', ...
                    'string', 'Add', ...
                    'enable', 'off',...              
                    'value', 1,...      
                    'callback', @edgesRadioCallback,...                    
                    'position', edgesAddPosition);  
    edgesAddAction ...
        = uicontrol(buildPanel, ...
                    'style', 'popup', ...
                    'string', '...', ...
                    'enable', 'off',...                    
                    'position', edgesAddActionPosition);                
    edgesRadio(2) ...
        = uicontrol(buildPanel, ...
                    'style', 'radiobutton', ...
                    'string', 'Remove', ...
                    'enable', 'off',...                 
                    'value', 0,...   
                    'callback', @edgesRadioCallback,...                    
                    'position', edgesRemovePosition);                   
    editRadioLabel ...
        = uicontrol(buildPanel, ...
                    'style', 'radiobutton', ...
                    'string', 'Edit', ...
                    'enable', 'on',...         
                    'value', 0,...
                    'callback', @modeCallback,...   
                    'position', editLabelPosition);                 
    graphPopupLabel ...
        = uicontrol(buildPanel, ...
                    'style', 'text', ...
                    'string', 'File', ...
                    'HorizontalAlignment','left',...
                    'backgroundcolor', bg_color, ...
                    'position', fileLabelPosition);  
    graphPopup ...
        = uicontrol(buildPanel, ...
                    'style', 'popup', ...
                    'string', 'Select option...|Load|Save', ...
                    'enable', 'on',...                    
                    'callback', @graphPopupClick,...                    
                    'position', filePosition);   
    
    % Collect gui elements for nodes
    nodeElements = {nodesRadio, nodesAddObservation};
    % And collect gui elements for edges
    edgeElements = {edgesRadio, edgesAddAction};
    
    % Update popups for actions and nodes so they show the right colours
    updateObservationsPopup();
    updateActionsPopup();
    
    %% FUNCTIONS
    function plotGraph()     
        axes(ax);
        cla(ax);        
        
        % Set node colours for graph
        nodesCols = hsv2rgb([(1:Graph.n_observations)'/Graph.n_observations, 0.5 * ones(Graph.n_observations,1), ones(Graph.n_observations,1)]);
        % Set action colours for graph
        edgesCols = hsv2rgb([(1:Graph.n_actions)'/Graph.n_actions, 0.5 * ones(Graph.n_actions,1), ones(Graph.n_actions,1)]);
        
        % Initialise nodes array
        nodes = -1*ones(Graph.n_locations,1);
        % Initialise edges cell array
        edges = cell(Graph.n_locations,1);
        
        % Update size of nodes
        nodesRadius = 0.01 + 1/(10*sqrt(Graph.n_locations));
        
        % Run through all locations and creat a circle for each
        for currLocation = 1:Graph.n_locations
            % Create new rectangle
            h = rectangle('Position', [Graph.locations(currLocation).x-nodesRadius, Graph.locations(currLocation).y-nodesRadius, nodesRadius*2, nodesRadius*2],...
                'Curvature', 1, 'ButtonDownFcn', {@nodeCallback, currLocation}, 'FaceColor', nodesCols(Graph.locations(currLocation).observation+1,:));
            % Add rectangle handle to array
            nodes(currLocation) = h;
            % Initialise action cell array for this location
            edges{currLocation} = cell(Graph.n_actions,1);
            % Now plot all actions for this location
            for currAction = 1:Graph.n_actions
                % Only plot actions that can actually be taken 
                if Graph.locations(currLocation).actions(currAction).probability > 0
                    % Find where this action takes you
                    nodeTo = find(Graph.locations(currLocation).actions(currAction).transition);
                    for currNodeTo = nodeTo
                        % Set patch coordinates
                        if currNodeTo == currLocation
                            % If this action goes to self: always point down
                            dir = 90;
                            % Set the patch coordinates to point from this location to transition location
                            xdat = Graph.locations(currLocation).x + nodesRadius*[2*cos(deg2rad(dir-30)); 2*cos(deg2rad(dir+30)); 3*cos(deg2rad(dir))];
                            ydat = Graph.locations(currLocation).y - nodesRadius*3 + nodesRadius*[2*sin(deg2rad(dir-30)); 2*sin(deg2rad(dir+30)); 3*sin(deg2rad(dir))];                                                                        
                        else
                            % Get the direction of this action
                            xvec = Graph.locations(currNodeTo).x-Graph.locations(currLocation).x;
                            yvec = Graph.locations(currLocation).y-Graph.locations(currNodeTo).y;
                            dir = atan2d(xvec*0-yvec*1,xvec*1+yvec*0);
                            % Set the patch coordinates to point from this location to transition location
                            xdat = Graph.locations(currLocation).x + nodesRadius*[2*cos(deg2rad(dir-30)); 2*cos(deg2rad(dir+30)); 3*cos(deg2rad(dir))];
                            ydat = Graph.locations(currLocation).y + nodesRadius*[2*sin(deg2rad(dir-30)); 2*sin(deg2rad(dir+30)); 3*sin(deg2rad(dir))];
                        end
                        % Create patch
                        h = patch(xdat,ydat,edgesCols(currAction,:));
                        % Store patch in cell array
                        edges{currLocation}{currAction}(end+1) = h;
                    end
                end
            end
        end        
    end
                
    function dummyCallback(source,callbackdata)
        disp('Callback');
    end   

    function axesCallback(source,callbackdata)
        % Get click position
        clickX = callbackdata.IntersectionPoint(1);
        clickY = callbackdata.IntersectionPoint(2);
        disp(['Axes ' num2str(clickX) ', ' num2str(clickY)]);        
        if (buildMode == 1) % Creating, removing or moving nodes 
            if (nodesMode == 1) % Creating node
                % Create new location entry in Graph object
                Graph.locations(Graph.n_locations+1).id = Graph.n_locations;
                Graph.locations(Graph.n_locations+1).observation = get(nodesAddObservation,'value') - 1;
                Graph.locations(Graph.n_locations+1).x = clickX;
                Graph.locations(Graph.n_locations+1).y = clickY;
                Graph.locations(Graph.n_locations+1).in_locations = [];
                Graph.locations(Graph.n_locations+1).in_degree = 0;                
                Graph.locations(Graph.n_locations+1).out_locations = [];
                Graph.locations(Graph.n_locations+1).out_degree = 0;   
                for currAction = 1:Graph.n_actions
                    Graph.locations(Graph.n_locations+1).actions(currAction).id = currAction-1;
                    Graph.locations(Graph.n_locations+1).actions(currAction).transition = zeros(1, Graph.n_locations+1);
                    Graph.locations(Graph.n_locations+1).actions(currAction).probability = 0;
                end
                Graph.adjacency = [Graph.adjacency zeros(Graph.n_locations,1)];
                Graph.adjacency = [Graph.adjacency; zeros(1,Graph.n_locations+1)];     
                Graph.adjacency
                % Update transition for all action to have an additional entry for this node
                for currLocation = 1:Graph.n_locations
                    for currAction = 1:Graph.n_actions
                        Graph.locations(currLocation).actions(currAction).transition = [Graph.locations(currLocation).actions(currAction).transition, 0];
                    end
                end
                % And finally, update number of locations
                Graph.n_locations = Graph.n_locations+1;
                % Create new location circle on axis
                axes(ax);
                h = rectangle('Position', [Graph.locations(Graph.n_locations).x-nodesRadius, Graph.locations(Graph.n_locations).y-nodesRadius, nodesRadius*2, nodesRadius*2],...
                    'Curvature', 1, 'ButtonDownFcn', {@nodeCallback, Graph.n_locations}, 'FaceColor', nodesCols(Graph.locations(Graph.n_locations).observation+1,:));
                nodes(Graph.n_locations) = h;
                % Create empty edges handles
                for currAction = 1:Graph.n_actions
                    edges{Graph.n_locations}{currAction} = [];
                end
            end
            if (nodesMode == 3) % Moving node
                if selectedNode ~= -1
                    % Update this location entry
                    Graph.locations(selectedNode).x = clickX;
                    Graph.locations(selectedNode).y = clickY;
                    % And move corresponding circle
                    set(nodes(selectedNode), 'Position', [Graph.locations(selectedNode).x-nodesRadius, Graph.locations(selectedNode).y-nodesRadius, nodesRadius*2, nodesRadius*2]);
                    % Also move all its actions
                    for currAction = 1:Graph.n_actions
                        % Find where this action takes you
                        nodeTo = find(Graph.locations(selectedNode).actions(currAction).transition);                        
                        for currPatchId = 1:length(edges{selectedNode}{currAction})
                            currNodeTo = nodeTo(currPatchId);
                            % Set patch coordinates
                            if currNodeTo == selectedNode
                                % If this action goes to self: always point down
                                dir = 90;
                                % Set the patch coordinates to point from this location to transition location
                                xdat = Graph.locations(selectedNode).x + nodesRadius*[2*cos(deg2rad(dir-30)); 2*cos(deg2rad(dir+30)); 3*cos(deg2rad(dir))];
                                ydat = Graph.locations(selectedNode).y - nodesRadius*3 + nodesRadius*[2*sin(deg2rad(dir-30)); 2*sin(deg2rad(dir+30)); 3*sin(deg2rad(dir))];                                                                        
                            else
                                % Get the direction of this action
                                xvec = Graph.locations(currNodeTo).x-Graph.locations(selectedNode).x;
                                yvec = Graph.locations(selectedNode).y-Graph.locations(currNodeTo).y;
                                dir = atan2d(xvec*0-yvec*1,xvec*1+yvec*0);
                                % Set the patch coordinates to point from this location to transition location
                                xdat = Graph.locations(selectedNode).x + nodesRadius*[2*cos(deg2rad(dir-30)); 2*cos(deg2rad(dir+30)); 3*cos(deg2rad(dir))];
                                ydat = Graph.locations(selectedNode).y + nodesRadius*[2*sin(deg2rad(dir-30)); 2*sin(deg2rad(dir+30)); 3*sin(deg2rad(dir))];
                            end
                            % Update patch
                            set(edges{selectedNode}{currAction}(currPatchId), 'Vertices', [xdat ydat]);
                        end
                    end
                    selectedNode = -1
                end
            end
        else % Building or removing edges
            if (edgesMode == 1) % Creating edge
                selectedNode = -1 % Not clicking on node means cancel               
            end
        end
    end 

    function nodeCallback(source,callbackdata,selectedLocation)
        disp(['clicked node ' num2str(selectedLocation) ', selected node ' num2str(selectedNode)]);        
        if buildMode ==1 % Creating, moving or removing nodes
            if (nodesMode == 2) % Removing node
                % Update adjacency matrix: remove row and column
                Graph.adjacency = Graph.adjacency(:,[1:(selectedLocation-1) (selectedLocation+1):Graph.n_locations]);
                Graph.adjacency = Graph.adjacency([1:(selectedLocation-1) (selectedLocation+1):Graph.n_locations],:);
                % Update locations
                for currLocation = 1:Graph.n_locations
                    % If this is the selected location: update all locations it can transition to
                    if currLocation == selectedLocation
                        % Update actions
                        for currAction = 1:Graph.n_actions
                            % Collect all nodes this action can transition to
                            nodesTo = find(Graph.locations(currLocation).actions(currAction).transition>0);
                            % Remove all actions leaving from the selected node
                            for currLocTo = nodesTo
                                removeAction(selectedLocation, currLocTo, currAction);
                            end
                            % Remove the selected location's entry from this action's transitions
                            Graph.locations(currLocation).actions(currAction).transition = Graph.locations(currLocation).actions(currAction).transition(1:Graph.n_locations ~= selectedLocation);
                        end
                    else
                        % Update actions
                        for currAction = 1:Graph.n_actions
                            % Collect all nodes this action can transition to
                            nodesTo = find(Graph.locations(currLocation).actions(currAction).transition>0);
                            for currLocTo = nodesTo
                                disp([num2str(currLocation) ', ' num2str(currLocTo) ', ' num2str(currAction)]);
                                % If this action leads to the selected node: remove it
                                if currLocTo == selectedLocation
                                    disp('removing action');
                                    removeAction(currLocation, currLocTo, currAction);
                                end
                            end
                            % Remove the selected location's entry from this action's transitions
                            Graph.locations(currLocation).actions(currAction).transition = Graph.locations(currLocation).actions(currAction).transition(1:Graph.n_locations ~= selectedLocation);                            
                        end
                    end
                end                       
                % After fixing all in_locations and out_locations: update ids (can't do this in the process of fixing because some ids would be old, others new) 
                for currLocation = 1:Graph.n_locations
                    % Fix ids
                    Graph.locations(currLocation).id = Graph.locations(currLocation).id - (currLocation > selectedLocation);
                    Graph.locations(currLocation).in_locations = Graph.locations(currLocation).in_locations - (Graph.locations(currLocation).in_locations > selectedLocation);
                    Graph.locations(currLocation).out_locations = Graph.locations(currLocation).out_locations - (Graph.locations(currLocation).out_locations > selectedLocation);
                    % Fix callback
                    set(nodes(currLocation), 'ButtonDownFcn', {@nodeCallback, currLocation - (currLocation > selectedLocation)})
                end
                % Remove rectangle hande for selected node
                delete(nodes(selectedLocation));
                % And get rid of the handle
                nodes=nodes(1:Graph.n_locations ~= selectedLocation);
                % Also get rid of the edges handle
                edges=edges(1:Graph.n_locations ~= selectedLocation);                
                % And finally, remove the location from the Graph
                Graph.locations = Graph.locations(1:Graph.n_locations ~= selectedLocation);
                % And decrease the number of nodes in the graph.
                Graph.n_locations = Graph.n_locations - 1;
                assignin('base','Graph',Graph);
            end
            if (nodesMode == 3) % Moving node
                selectedNode = selectedLocation;
            end
        elseif buildMode == 2 % Creating or removing edges
            if selectedNode == -1
                selectedNode = selectedLocation;
            else
                if edgesMode == 1 % Add edge
                    % Get the current action
                    currAction = get(edgesAddAction,'Value');                    
                    % Only add edge if it doesn't exist yet
                    if Graph.locations(selectedNode).actions(currAction).transition(selectedLocation) == 0
                        % Update adjacency matrix
                        Graph.adjacency(selectedNode,selectedLocation) = 1;
                        % Get probabilities across actions at starting location
                        probs = [Graph.locations(selectedNode).actions(:).probability];
                        % If this action had zero probability before: make that probability non-zero
                        if any(probs>0)
                            Graph.locations(selectedNode).actions(currAction).probability = mean(probs(probs>0));
                        else
                            Graph.locations(selectedNode).actions(currAction).probability = 1;
                        end
                        % Renormalise action probabilities and update them
                        probs = num2cell([Graph.locations(selectedNode).actions(:).probability] / sum([Graph.locations(selectedNode).actions(:).probability]));
                        [Graph.locations(selectedNode).actions(:).probability] = probs{:};                                                
                        % Add this transition to the action
                        if any(Graph.locations(selectedNode).actions(currAction).transition > 0)
                            Graph.locations(selectedNode).actions(currAction).transition(selectedLocation) = mean(Graph.locations(selectedNode).actions(currAction).transition(Graph.locations(selectedNode).actions(currAction).transition>0));
                        else
                            Graph.locations(selectedNode).actions(currAction).transition(selectedLocation) = 1;
                        end
                        % And renormalise transitions
                        Graph.locations(selectedNode).actions(currAction).transition = Graph.locations(selectedNode).actions(currAction).transition / sum(Graph.locations(selectedNode).actions(currAction).transition);
                        % Update out-degree and out-locations for this node
                        Graph.locations(selectedNode).out_locations = unique([Graph.locations(selectedNode).out_locations, selectedLocation]);
                        Graph.locations(selectedNode).out_degree = Graph.locations(selectedNode).out_degree + 1;
                        % Update in-degree and in-locations for the transitioned location
                        Graph.locations(selectedLocation).in_locations = unique([Graph.locations(selectedLocation).in_locations, selectedNode]);
                        Graph.locations(selectedLocation).in_degree = Graph.locations(selectedLocation).in_degree + 1;                        
                        % Add patch for this action. Make sure to keep patches in order of transitions
                        currPatch = find(find(Graph.locations(selectedNode).actions(currAction).transition) == selectedLocation);
                        % Set patch coordinates
                        if selectedLocation == selectedNode
                            % If this action goes to self: always point down
                            dir = 90;
                            % Set the patch coordinates to point from this location to transition location
                            xdat = Graph.locations(selectedNode).x + nodesRadius*[2*cos(deg2rad(dir-30)); 2*cos(deg2rad(dir+30)); 3*cos(deg2rad(dir))];
                            ydat = Graph.locations(selectedNode).y - nodesRadius*3 + nodesRadius*[2*sin(deg2rad(dir-30)); 2*sin(deg2rad(dir+30)); 3*sin(deg2rad(dir))];                                                                        
                        else
                            % Get the direction of this action
                            xvec = Graph.locations(selectedLocation).x-Graph.locations(selectedNode).x;
                            yvec = Graph.locations(selectedNode).y-Graph.locations(selectedLocation).y;
                            dir = atan2d(xvec*0-yvec*1,xvec*1+yvec*0);
                            % Set the patch coordinates to point from this location to transition location
                            xdat = Graph.locations(selectedNode).x + nodesRadius*[2*cos(deg2rad(dir-30)); 2*cos(deg2rad(dir+30)); 3*cos(deg2rad(dir))];
                            ydat = Graph.locations(selectedNode).y + nodesRadius*[2*sin(deg2rad(dir-30)); 2*sin(deg2rad(dir+30)); 3*sin(deg2rad(dir))];
                        end                        
                        % Make new patch
                        h = patch(xdat,ydat,edgesCols(currAction,:));
                        % And store its handle, but in the right place between other patches
                        edges{selectedNode}{currAction} = [edges{selectedNode}{currAction}(1:currPatch - 1), h, edges{selectedNode}{currAction}(currPatch:end)];
                        assignin('base','edges',edges);
                        assignin('base','Graph',Graph);
                    else
                        disp('action already exists')
                    end
                    
                end
                if edgesMode == 2 % Remove edge. This will remove all actions between nodes
                    % Run through all possible actions
                    for currAction = 1:Graph.n_actions
                        % Remove the action corresponding to the indicated transition
                        removeAction(selectedNode, selectedLocation, currAction);                        
                    end
                    % Update adjacency matrix
                    Graph.adjacency(selectedNode,selectedLocation) = 0;
                end
                selectedNode = -1;                
            end
        elseif buildMode == 3 % Editing node properties
            % Show popup dialog with info about selected node
            params = editDialog(Graph, selectedLocation);
            % Update the observation for the selected node
            Graph.locations(selectedLocation).observation = params.observation;
            set(nodes(selectedLocation),'FaceColor', nodesCols(Graph.locations(selectedLocation).observation+1,:));
            % Remove all actions as requested by setting probabilities to zero
            for currActionIndex = 1:length(params.availableActions)
                currAction = params.availableActions(currActionIndex);
                for currTransitionIndex = 1:length(params.availableTransitions{currActionIndex})
                    currTransition = params.availableTransitions{currActionIndex}(currTransitionIndex);
                    % If the policy of this action has been set to 0: remove this action
                    if params.actionProbabilities(currActionIndex) == 0
                        removeAction(selectedLocation, currTransition, currAction);
                    else
                        % If the transition probability of this action has been set to 0: remove this action
                        if params.transitionProbabilities{currActionIndex}(currTransitionIndex) == 0
                            removeAction(selectedLocation, currTransition, currAction);
                        end
                    end
                end
            end
            % Now set all probabilities, both for actions and transitions. This must be done after action removal because there is renormalisation in action removal
            for currActionIndex = 1:length(params.availableActions)
                currAction = params.availableActions(currActionIndex);
                Graph.locations(selectedLocation).actions(currAction).probability = params.actionProbabilities(currActionIndex);
                for currTransitionIndex = 1:length(params.availableTransitions{currActionIndex})
                    currTransition = params.availableTransitions{currActionIndex}(currTransitionIndex);
                    Graph.locations(selectedLocation).actions(currAction).transition(currTransition) = params.transitionProbabilities{currActionIndex}(currTransitionIndex);
                end
            end
            % Since some actions may have been removed, the adjacency matrix may have changed. Rebuild it.
            rebuildAdjacency()
            % Send updated graph to workspace
            assignin('base','Graph',Graph);
        end
    end   
        
    function graphPopupClick(source,callbackdata)
        choice = get(source, 'value');
        set(source,'value', 1);
        switch choice
            case 2
                % Show file loading dialog
                [filename, pathname] = uigetfile({'*.mat;*.json;*.txt','Graph file'},'Choose graph file');

                % User pressed cancel
                if (isequal(filename, 0) || isequal(pathname,0))
                    return;
                end
                
                % Find extension of selected file
                [~,~,ext] = fileparts(filename);
                
                % If matlab file selected: load matlab struct
                if isequal(ext,'.mat')
                    % Get graph from file
                    newDat = load(fullfile(pathname, filename));
                    Graph = newDat.Graph;
                else
                    % All other cases: this is a text file with json-encoded graph.
                    Graph = jsondecode(fileread(fullfile(pathname, filename)));
                end
                
                % Plot loaded graph
                plotGraph();
            case 3
                % Show file dialog
                [filename, pathname] = uiputfile({'*.mat', 'Matlab Graph (*.mat)'; '*.json', 'JSON Graph (*.json)'; '*.txt', 'Plaintext JSON Graph (*.txt)'}, 'Save graph');                                
                if (isequal(filename,0) || isequal(pathname,0)) % User pressed cancel
                    return;
                else
                    % Find extension of selected file
                    [~,~,ext] = fileparts(filename);    
                    % Export data to workspace
                    assignin('base', 'Graph', Graph);
                    % If this a .mat file: save matlab struct
                    if isequal(ext,'.mat')
                        % Export data to mat file
                        save(fullfile(pathname,filename), 'Graph');
                    else
                        % And save json file
                        fileID = fopen(fullfile(pathname,filename),'w');
                        fprintf(fileID,jsonencode(Graph));
                        fclose(fileID);
                    end
                end  
        end
    end

    function buildButtonCallback(source,callbackdata)
        % Get new graph parameters
        rows = str2double(get(buildDimensionsRows, 'String'));
        columns = str2double(get(buildDimensionsColumns, 'String'));
        connected = get(buildSetConnected, 'Value');
        wrap = get(buildSetWrap,'Value');
        self = get(buildSetSelf,'Value');
        observations = str2double(get(nodesObservations,'String'));
        if isnan(observations)
            observations = rows*columns;            
        end
        
        % Build graph
        Graph = buildEnvironment(rows, columns, observations, connected, wrap, self, graphMode);
        % Plot new graph
        plotGraph();           
        
        % Update number of actions and observations
        set(edgesActions,'String',num2str(Graph.n_actions));
        set(nodesObservations,'String',num2str(Graph.n_observations));
        % Update popups for adding actions and locations
        updateObservationsPopup()
        updateActionsPopup()
        
        % Save to workspace for inspection
        assignin('base','Graph',Graph);
    end 

    function nodesRadioCallback(source, EventData)
        for i = 1:3
            if source == nodesRadio(i)
                set(nodesRadio(i), 'Value', 1);
                nodesMode = i;
            else
                set(nodesRadio(i), 'Value', 0);
            end
        end
    end

    function edgesRadioCallback(source, EventData)
        for i = 1:2
            if source == edgesRadio(i)
                set(edgesRadio(i), 'Value', 1);
                edgesMode = i;
            else
                set(edgesRadio(i), 'Value', 0);
            end
        end
    end

    function buildRadioCallback(source, EventData)
        for i = 1:2
            if source == buildRadio(i)
                set(buildRadio(i), 'Value', 1);
                graphMode = i;
            else
                set(buildRadio(i), 'Value', 0);
            end
        end
    end

    function modeCallback(source, EventData)
        if source == nodesRadioLabel
            set(nodesRadioLabel, 'Value', 1);            
            set(edgesRadioLabel, 'Value', 0);
            set(editRadioLabel, 'Value', 0);                        
            buildMode = 1;
            selectedNode = -1;
            for currElement = 1:length(nodeElements)
                for currElementEntry = 1:length(nodeElements{currElement})
                    set(nodeElements{currElement}(currElementEntry),'enable','on');
                end
            end
            for currElement = 1:length(edgeElements)
                for currElementEntry = 1:length(edgeElements{currElement})
                    set(edgeElements{currElement}(currElementEntry),'enable','off');
                end
            end    
        elseif source == edgesRadioLabel
            set(nodesRadioLabel, 'Value', 0);                        
            set(edgesRadioLabel, 'Value', 1);
            set(editRadioLabel, 'Value', 0);                        
            buildMode = 2;
            selectedNode = -1;
            for currElement = 1:length(nodeElements)
                for currElementEntry = 1:length(nodeElements{currElement})
                    set(nodeElements{currElement}(currElementEntry),'enable','off');
                end
            end
            for currElement = 1:length(edgeElements)
                for currElementEntry = 1:length(edgeElements{currElement})
                    set(edgeElements{currElement}(currElementEntry),'enable','on');
                end
            end
        elseif source == editRadioLabel
            set(nodesRadioLabel, 'Value', 0);                        
            set(edgesRadioLabel, 'Value', 0);
            set(editRadioLabel, 'Value', 1);    
            buildMode = 3;
            selectedNode = -1;
            for currElement = 1:length(nodeElements)
                for currElementEntry = 1:length(nodeElements{currElement})
                    set(nodeElements{currElement}(currElementEntry),'enable','off');
                end
            end
            for currElement = 1:length(edgeElements)
                for currElementEntry = 1:length(edgeElements{currElement})
                    set(edgeElements{currElement}(currElementEntry),'enable','off');
                end
            end            
        end
    end

    function nodesObservationsCallback(source, EventData)
        % Convert the set observations to a number
        newObservations = str2double(get(nodesObservations,'String'));
        % If this is not a number: change it back to previous value, and exit
        if isnan(newObservations)
            set(nodesObservations,'String',num2str(Graph.n_observations));
            return;
        end
        % Update number of observations field in graph
        Graph.n_observations = newObservations;
        % Run through all locations to make sure there are no illegal observations
        for currLocation = 1:Graph.n_locations
            if Graph.locations(currLocation).observation+1 > Graph.n_observations
                Graph.locations(currLocation).observation = randi(Graph.n_observations)-1;
            end
        end
        % Update colours for new set of observations
        nodesCols = hsv2rgb([(1:Graph.n_observations)'/Graph.n_observations, 0.5 * ones(Graph.n_observations,1), ones(Graph.n_observations,1)]);
        % Run through all nodes and set their colour accordingly
        for currLocation = 1:Graph.n_locations
            set(nodes(currLocation),'FaceColor', nodesCols(Graph.locations(currLocation).observation+1,:));
        end
        % Update the value in the observations edit box
        set(nodesObservations,'String',num2str(Graph.n_observations));        
        % Update the value in the add node popup
        updateObservationsPopup();
    end

    function updateObservationsPopup()
        % Start with empty string
        newString='';
        % Create coloured entry for each observation
        for currObservation = 1:Graph.n_observations
            newString = [newString '<html><font color="' rgb2hex(nodesCols(currObservation,:)) '">' num2str(currObservation-1) '</font></html>|'];
        end
        % Remove last separation character
        newString = newString(1:(end-1));
        % Update the value of the popup so it can't be out of range
        set(nodesAddObservation,'Value',min(get(nodesAddObservation,'Value'), Graph.n_observations));        
        % And update popup string
        set(nodesAddObservation,'String',newString);
    end

    function edgesActionsCallback(source, EventData)
        % Convert the set observations to a number
        newActions = str2double(get(edgesActions,'String'));
        % If this is not a number: change it back to previous value, and exit
        if isnan(newActions)
            set(edgesActions,'String',num2str(Graph.n_actions));
            return;
        end
        % Run through all locations to update the action entries
        for currLocation = 1:Graph.n_locations
            % Remove all actions that are above the new number of actions (only executed if newActions < Graph.n_actions)
            for currAction = (newActions + 1):Graph.n_actions
                % Find all nodes that this action leads to
                transitions = find(Graph.locations(currLocation).actions(currAction).transition);
                % And remove each of them
                for currTo = transitions
                    removeAction(currLocation, currTo, currAction);
                end
            end
            % Remove all actions above the new number of actions
            edges{currLocation} = edges{currLocation}(1:min(Graph.n_actions, newActions));
            % Add all actions that are above the old number of actions (only executed if newActions > Graph.n_actions)
            for currAction = (Graph.n_actions + 1):newActions
                Graph.locations(currLocation).actions(currAction).id = currAction - 1;
                Graph.locations(currLocation).actions(currAction).transition = zeros(1,Graph.n_locations);
                Graph.locations(currLocation).actions(currAction).probability = 0;
                % Also add empty entry in patch array
                edges{currLocation}{currAction} = [];
            end
        end
        % Update adjacency matrix, which may have changed after removing actions
        rebuildAdjacency();
        % Update number of observations field in graph
        Graph.n_actions = newActions;        
        % Update colours for new set of actions
        edgesCols = hsv2rgb([(1:Graph.n_actions)'/Graph.n_actions, 0.5 * ones(Graph.n_actions,1), ones(Graph.n_actions,1)]);
        % Run through all actions and set their colour accordingly
        for currLocation = 1:Graph.n_locations
            for currAction = 1:Graph.n_actions
                for currToIndex = 1:length(edges{currLocation}{currAction})
                    set(edges{currLocation}{currAction}(currToIndex),'FaceColor', edgesCols(currAction,:));
                end
            end
        end
        % Update the value in the observations edit box
        set(edgesActions,'String',num2str(Graph.n_actions));        
        % Update the value in the add node popup
        updateActionsPopup();
    end

    function updateActionsPopup()
        % Start with empty string
        newString='';
        % Create coloured entry for each observation
        for currAction = 1:Graph.n_actions
            newString = [newString '<html><font color="' rgb2hex(edgesCols(currAction,:)) '">' num2str(currAction-1) '</font></html>|'];
        end
        % Remove last separation character
        newString = newString(1:(end-1));
        % Update the value of the popup so it can't be out of range
        set(edgesAddAction,'Value',min(get(edgesAddAction,'Value'), Graph.n_actions));
        % And update popup string
        set(edgesAddAction,'String',newString);
    end

    function removeAction(locFrom, locTo, action)
        %keyboard;
        % See if this action exists 
        if Graph.locations(locFrom).actions(action).transition(locTo) > 0
            % Update out-degree
            Graph.locations(locFrom).out_degree = Graph.locations(locFrom).out_degree - 1;
            % Update out-locations
            Graph.locations(locFrom).out_locations = Graph.locations(locFrom).out_locations(Graph.locations(locFrom).out_locations~=(locTo-1));
            % Update in-degree
            Graph.locations(locTo).in_degree = Graph.locations(locTo).in_degree - 1;
            % Update in-locations
            Graph.locations(locTo).in_locations = Graph.locations(locTo).in_locations(Graph.locations(locTo).in_locations~=(locFrom-1));
            % Find which transition this is
            transIndex = find(find(Graph.locations(locFrom).actions(action).transition)==locTo);
            % Remove corresponding patch
            delete(edges{locFrom}{action}(transIndex));
            % And remove that patch from edges
            edges{locFrom}{action} = [edges{locFrom}{action}(1:(transIndex-1)) edges{locFrom}{action}((transIndex+1):end)];
            % Set this transition to zero
            Graph.locations(locFrom).actions(action).transition(locTo) = 0;
            % Renormalise transitions
            if sum(Graph.locations(locFrom).actions(action).transition) > 0
                Graph.locations(locFrom).actions(action).transition = Graph.locations(locFrom).actions(action).transition / sum(Graph.locations(locFrom).actions(action).transition);
            else
                % No transitions for this action anymore: set its probability to 0
                Graph.locations(locFrom).actions(action).probability = 0;
                % If there are any non-zero probabilities left: renormalise probabilities
                if any([Graph.locations(locFrom).actions(:).probability]>0)
                    probs = num2cell([Graph.locations(locFrom).actions(:).probability] / sum([Graph.locations(locFrom).actions(:).probability]));
                    [Graph.locations(locFrom).actions(:).probability] = probs{:};                                                
                end
            end
        end         
    end

    function rebuildAdjacency()
        % Reset adjacency matrix
        Graph.adjacency = zeros(Graph.n_locations);
        % Run through locations
        for currLocation = 1:Graph.n_locations
            % Run through actions
            for currAction = 1:Graph.n_actions
                % Update adjacency from transition of this action, if this action is available
                if Graph.locations(currLocation).actions(currAction).probability > 0
                    Graph.adjacency(currLocation,Graph.locations(currLocation).actions(currAction).transition > 0) = 1;
                end
            end
        end
    end
end
