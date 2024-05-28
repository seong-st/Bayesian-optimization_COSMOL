function optimizeSections2()
    I_bounds = [56, 224+56];
%     t_bounds_sections = [0, 50; 200, 250; 400, 450; 600, 650];
    sections = {'std1', 'std2', 'std3', 'std4'};
    duration = 100;

    t_start = zeros(1, length(sections));

    t_start(1) = 0;

    for i = 1:length(sections)
        fprintf('Optimizing Section %d...\n', i);
%         t_bounds = t_bounds_sections(i, :);

        if i > 1
            t_start(i) = bestVarsRef.Value.chargingTime;
        end

        t_bounds = [t_start(i), t_start(i) + duration];

        bestVarsRef = RefValue([]);
        maxEtaRef = RefValue(-Inf);

        optimizeSection(I_bounds, t_bounds, sections{i}, bestVarsRef, maxEtaRef);
        
        fprintf('Best Results for Section %d with Max Eta %f:\n', i, maxEtaRef.Value);
        disp(bestVarsRef.Value);
    end
end

function optimizeSection(I_bounds, t_bounds, studyName, bestVarsRef, maxEtaRef)
    vars = [
        optimizableVariable('I1', I_bounds, 'Type', 'real');
        optimizableVariable('I2', I_bounds, 'Type', 'real');
        optimizableVariable('I3', I_bounds, 'Type', 'real');
        optimizableVariable('I4', I_bounds, 'Type', 'real');
        optimizableVariable('t1', [t_bounds(1), t_bounds(2)], 'Type', 'real');
        optimizableVariable('t2', [t_bounds(1) + 75, t_bounds(2) + 75], 'Type', 'real');
        optimizableVariable('t3', [t_bounds(1) + 150, t_bounds(2) + 150], 'Type', 'real');
    ];

    bayesopt(@(params) objectiveFunction(params, studyName, bestVarsRef, maxEtaRef), vars, ...
        'MaxObjectiveEvaluations', 3, ...
        'AcquisitionFunctionName', 'expected-improvement-plus', ...
        'IsObjectiveDeterministic', false);

%     chargingTime = results.UserDataTrace{end}.chargingTime;
%     return chargingTime;
end

function chargingTime = objectiveFunction(params, studyName, bestVarsRef, maxEtaRef)
    model = mphopen('BO.mph');
    model.param.set('I1', params.I1);
    model.param.set('I2', params.I2);
    model.param.set('I3', params.I3);
    model.param.set('I4', params.I4);
    model.param.set('t1', params.t1);
    model.param.set('t2', params.t2);
    model.param.set('t3', params.t3);
    model.study(studyName).run;

    eta = mphglobal(model, 'Eta');
    eta = eta(end,:);
    chargingTime = mphglobal(model, 'chargetime');
    chargingTime = chargingTime(end,:);
    


    model.param.set('startTime',chargingTime);

    if eta > maxEtaRef.Value
        maxEtaRef.Value = eta;
        bestVarsRef.Value = struct('params', params, 'chargingTime', chargingTime);
    end
       

    if strcmp(studyName, 'std1')
        
        etaThreshold = 0;  %%% phis-phil 1 < 1.2[mV]
        maxPenalty = 1e3;
        if eta < etaThreshold
            chargingTime = maxPenalty;
        end

%          model.param.set('startTime2', chargingTime);
    end
   

    if strcmp(studyName, 'std2')

        model.study('std2').feature('time').set('tlist', 'range(0+startTime, 4, 30000)');

%         model.study('std2').run

        model.result('pg21').run;
        model.result('pg20').run;

        chargingTime = model.result('pg21').feature('glob1').getDouble('xmax');
        disp(['chargingTime  = ' , num2str(chargingTime)]);

        eta = model.result('pg20').feature('glob1').getDouble('ymin');
        

        etaThreshold = 0;   %%% phis-phil 2 < 8[mV]
        maxPenalty2 = 1e3;
        if eta < etaThreshold
            chargingTime = maxPenalty2;
        end

%         model.param.set('startTime3', chargingTime);
    end
    
    if strcmp(studyName, 'std3')

        model.study('std3').feature('time').set('tlist', 'range(0+startTime, 4, 30000)');
%         model.study('std3').run

        model.result('pg39').run;
        model.result('pg38').run;

        chargingTime = model.result('pg39').feature('glob1').getDouble('xmax');
        disp(['chargingTime  = ' , num2str(chargingTime)]);

        eta = model.result('pg38').feature('glob1').getDouble('ymin');
        

        etaThreshold = 0;   %%% phis-phil 3< 4[mV]
        maxPenalty3 = 2e3;
        if eta < etaThreshold
            chargingTime = maxPenalty3;
        end

%         model.param.set('startTime4', chargingTime);
    end

    if strcmp(studyName, 'std4')

        model.study('std3').feature('time').set('tlist', 'range(0+startTime, 4, 30000)');
        model.study('std3').run


        model.result('pg41').run;
        model.result('pg40').run;

        chargingTime = model.result('pg41').feature('glob1').getDouble('xmax');
        disp(['chargingTime  = ' , num2str(chargingTime)]);

        eta = model.result('pg40').feature('glob1').getDouble('ymin');
        

        etaThreshold = 0;   %%% phis-phil < 0[V]
        maxPenalty4 = 3e3;
        if eta < etaThreshold
            chargingTime = maxPenalty4;
         end
    end

%      if eta > maxEtaRef.Value
%         maxEtaRef.Value = eta;
%         bestVarsRef.Value = params;
%     end
%        

    disp(['Eta  = ' , num2str(eta)]);

end