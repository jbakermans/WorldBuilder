% Jacob Bakermans, January 2016
function params = editDialog(Graph, selectedLocation)
    % determine window size
    screensize = get(0, 'screensize');
    winsize = round([min(1 * screensize(4), 300), min(0.5 * screensize(4), 300)]);
    winoffset = round(0.5 * (screensize(3:4)-winsize));

    window = dialog('name', 'Edit location', ...
                         'color', [0.95 0.95 0.95], ...
                         'units', 'pixels', ...
                         'position', [winoffset(:)' winsize(:)'], ...                         
                         'CloseRequestFcn', @cancel, ...
                         'DefaultUIPanelBackGroundColor', [0.95 0.95 0.95], ...
                         'DefaultUIControlUnits', 'normalized',...
                         'DefaultAxesLooseInset', [0.00, 0, 0, 0], ... 
                         'DefaultAxesUnits', 'normalized');
    
    % initialize output
    params = struct();    
    
    % Initialise observation
    params.observation = Graph.locations(selectedLocation).observation;
    % Find number of actions available at selected location
    params.availableActions = [];
    params.actionProbabilities = [];
    params.availableTransitions = {};
    params.transitionProbabilities = {};
    for currAction = 1:Graph.n_actions
        if Graph.locations(selectedLocation).actions(currAction).probability > 0
            % If this action has a >0 probability: include it as available
            params.availableActions(end+1) = currAction;
            % And store the corresponding probability
            params.actionProbabilities(end+1) = Graph.locations(selectedLocation).actions(currAction).probability;
            % Also store all transitions for this action
            params.availableTransitions{end+1} = find(Graph.locations(selectedLocation).actions(currAction).transition>0);
            % And store the corresponding probabilities
            params.transitionProbabilities{end+1} = Graph.locations(selectedLocation).actions(currAction).transition(params.availableTransitions{end});
        end
    end   
    
    % Get number of rows for this ui: 6 + number of available actions
    uiRows = 6 + length(params.availableActions);
    
    % width and height in pixels
    windowPos = get(window,'Position');
    
    % Default is 10 rows. Use that to update the new gui height
    windowPos(4) = windowPos(4)/10*uiRows;
    set(window,'Position',windowPos);

    % vertical and horizontal padding 
    uivp = 0.01;
    uihp = 0.03;
    % tab for indentation
    uiTab = 0.1;
    
    % button height and width
    uiWidth = 1; % Padding included
    uiHeight = 1/uiRows; % Padding included    
    uiTabWidth = uiWidth-uiTab; % Padding included
    uiFieldWidth = uiTabWidth/2; % Padding included
    uiX = 0;    
    startY = 1;           
    
    % Graph ui positions
    locationLabelPosition = [(uiX + uihp) startY-uiHeight+uivp (uiWidth-2*uihp) (uiHeight -2*uivp)];
    locationObservationLabelPosition = [(uiX + uiTab + uihp) locationLabelPosition(2)-uiHeight (uiFieldWidth-2*uihp) (uiHeight -2*uivp)];
    locationObservationPopupPosition = [(uiX + uiTab + uiFieldWidth + uihp) locationLabelPosition(2)-uiHeight (uiFieldWidth-2*uihp) (uiHeight -2*uivp)];
    actionLabelPosition = [(uiX + uihp) locationObservationPopupPosition(2)-uiHeight (uiWidth-2*uihp) (uiHeight -2*uivp)];
    actionProbabilityLabelPosition = [(uiX + uiTab + uihp) actionLabelPosition(2)-uiHeight (uiFieldWidth-2*uihp) (uiHeight -2*uivp)];
    actionProbabilityEditPosition = [(uiX + uiTab + uiFieldWidth + uihp) actionLabelPosition(2)-uiHeight (uiFieldWidth-2*uihp) (uiHeight -2*uivp)];
    transitionLabelPosition = [(uiX + uihp) actionProbabilityEditPosition(2)-uiHeight (uiWidth-2*uihp) (uiHeight -2*uivp)];
    % Cell array for transitions for each available action
    actionTransitionPositions = cell(length(params.availableActions),2);
    for currActionIndex = 1:length(params.availableActions)
        % First action starts after previous position
        if currActionIndex == 1
            yPrev = transitionLabelPosition(2);
        else
            yPrev = actionTransitionPositions{currActionIndex-1,2}(2);
        end
        % First column of cell array: label position
        actionTransitionPositions{currActionIndex,1} = [(uiX + uiTab + uihp) yPrev-uiHeight (uiFieldWidth-2*uihp) (uiHeight -2*uivp)];
        % Second column of cell array: edit position
        actionTransitionPositions{currActionIndex,2} = [(uiX + uiTab + uiFieldWidth + uihp) yPrev-uiHeight (uiFieldWidth-2*uihp) (uiHeight -2*uivp)];    
    end
    % Last row: save and cancel button
    saveButtonPosition = [(uiX + uiTab + uihp) uivp (uiFieldWidth-2*uihp) (uiHeight -2*uivp)];    
    cancelButtonPosition = [(uiX + uiTab + uiFieldWidth + uihp) uivp (uiFieldWidth-2*uihp) (uiHeight -2*uivp)];    
        
    % ui elements: 6 rows, 2 columns
    textLocation ...
        = uicontrol(window, ...
            'style', 'text', ...
            'string', ['Location ' num2str(selectedLocation-1)], ...
            'horizontalalignment', 'left', ...
            'position', locationLabelPosition);
    textObservation ...
        = uicontrol(window, ...
            'style', 'text', ...
            'string', 'Observation', ...
            'horizontalalignment', 'left', ...
            'position', locationObservationLabelPosition);        
    popupObservation ...
        = uicontrol(window, ...
            'style', 'popup', ...
            'string', '...', ...
            'position', locationObservationPopupPosition);  
    textAction ...
        = uicontrol(window, ...
            'style', 'text', ...
            'string', 'Action probability', ...
            'horizontalalignment', 'left', ...
            'position', actionLabelPosition);             
    textActionProbability ...
        = uicontrol(window, ...
            'style', 'text', ...
            'string', ['Action ' regexprep(num2str(params.availableActions - 1),'\s+',', ')], ...
            'horizontalalignment', 'left', ...
            'position', actionProbabilityLabelPosition);   
    editActionProbability ...
        = uicontrol(window, ...
            'style', 'edit', ...
            'backgroundcolor', [1 1 1], ...            
            'string', regexprep(num2str(params.actionProbabilities, 2),'\s+',', '), ...   
            'position', actionProbabilityEditPosition);           
    textTransitionLabel ...
        = uicontrol(window, ...
            'style', 'text', ...
            'string', 'Transition probability', ...
            'horizontalalignment', 'left', ...
            'position', transitionLabelPosition);             

    % Create an entry for each available action
    for currActionIndex = 1:length(params.availableActions)
        currAction = params.availableActions(currActionIndex);
        % Create text
        textTransition(currActionIndex) ...
            = uicontrol(window, ...
                'style', 'text', ...
                'string', ['Action ' num2str(currAction) ': to ' regexprep(num2str(params.availableTransitions{currActionIndex}),'\s+',', ')], ...
                'horizontalalignment', 'left', ...
                'position', actionTransitionPositions{currActionIndex,1});      
        % And edit field
        editTransition(currActionIndex) ...
            = uicontrol(window, ...
                'style', 'edit', ...
                'backgroundcolor', [1 1 1], ... 
                'string', regexprep(num2str(params.transitionProbabilities{currActionIndex}, 2),'\s+',', '), ...
                'position', actionTransitionPositions{currActionIndex,2});             
    end
          
    okButton ...
        = uicontrol(window, ...
            'style', 'pushbutton', ...
            'string', 'Ok', ...
            'position', saveButtonPosition, ...
            'callback', @OK);
    cancelButton ...
        = uicontrol(window, ...
            'style', 'pushbutton', ...
            'string', 'Cancel', ...
            'position', cancelButtonPosition, ...
            'callback', @cancel);               
    
    % Update observations popup
    updateObservationsPopup();
    
    function updateObservationsPopup()
        % Update colours for new set of observations
        nodesCols = hsv2rgb([(1:Graph.n_observations)'/Graph.n_observations, 0.5 * ones(Graph.n_observations,1), ones(Graph.n_observations,1)]);        
        % Start with empty string
        newString='';
        % Create coloured entry for each observation
        for currObservation = 1:Graph.n_observations
            newString = [newString '<html><font color="' rgb2hex(nodesCols(currObservation,:)) '">' num2str(currObservation-1) '</font></html>|'];
        end
        % Remove last separation character
        newString = newString(1:(end-1));
        % Update the value of the popup to the current observation
        set(popupObservation,'Value',Graph.locations(selectedLocation).observation+1);        
        % And update popup string
        set(popupObservation,'String',newString);
    end                
        
    function OK(source,callbackdata)
        % When you choose OK: copy the current values into params struct
        newObservation = get(popupObservation,'Value')-1;
        newProbabilities = sscanf(get(editActionProbability,'String'), '%g,')';
        for currActionIndex = 1:length(params.availableActions)
            newActionProbabilities{currActionIndex} = sscanf(get(editTransition(currActionIndex),'String'), '%g,');
        end
        % Copy these new values into params, after verifying and normalising them if necessary
        for currActionIndex = 1:length(params.availableActions)
            if length(newActionProbabilities{currActionIndex}) == length(params.transitionProbabilities{currActionIndex})
                if sum(newActionProbabilities{currActionIndex}) > 0
                    % If there are some non-zero transition probabilities: normalise them                    
                    params.transitionProbabilities{currActionIndex} = newActionProbabilities{currActionIndex} / sum(newActionProbabilities{currActionIndex});
                else
                    % If there are no non-zero transition probabilities: simply copy the zeros                                        
                    params.transitionProbabilities{currActionIndex} = newActionProbabilities{currActionIndex};
                    % But an action with all-zero transition probability is rubbish, so do update the action probability to zero
                    newProbabilities(currActionIndex) = 0;
                end
            end
        end
        params.observation = newObservation;
        if length(newProbabilities) == length(params.actionProbabilities)
            if sum(newProbabilities) > 0
                % If there are some non-zero action probabilities: normalise them
                params.actionProbabilities = newProbabilities / sum(newProbabilities);
            else
                % If all action probabilities are zero: simply copy the zeros
                params.actionProbabilities = newProbabilities;
            end
        end        
        uiresume();
        delete(window);
    end

    function cancel(source,callbackdata)
        uiresume();
        delete(window);
    end

    uiwait(window);                    
end

