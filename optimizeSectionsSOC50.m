function optimizeSectionsSOC50()
    I_bounds = [56, 224];
    sections = {'std1', 'std2'};
    duration = 150;
    t_start = zeros(1, length(sections));
    t_start(1) = 0;




    for i = 1:length(sections)
        fprintf('Optimizing Section %d...\n', i);
        
        t_bounds = [t_start(i), t_start(i) + duration];
        endTime = optimizeSection(I_bounds, t_bounds, sections{i});

        if i < length(sections)
            t_start(i+1) = endTime;
        end
        
        fprintf('End of Section %d at time = %f\n', i, endTime);
    end
end

function endTime = optimizeSection(I_bounds, t_bounds, studyName)
    vars = [
        optimizableVariable('I1', I_bounds, 'Type', 'real');
        optimizableVariable('I2', I_bounds, 'Type', 'real');
        optimizableVariable('I3', I_bounds, 'Type', 'real');
        optimizableVariable('I4', I_bounds, 'Type', 'real');
        optimizableVariable('t1', [t_bounds(1), t_bounds(2)], 'Type', 'real');
        optimizableVariable('t2', [t_bounds(1) + 150, t_bounds(1) + 300], 'Type', 'real');
        optimizableVariable('t3', [t_bounds(1) + 300, t_bounds(1) + 450], 'Type', 'real');
    ];

    results = bayesopt(@(params) objectiveFunction(params, studyName), vars, ...
        'MaxObjectiveEvaluations', 50, ...
        'AcquisitionFunctionName', 'expected-improvement-plus', ...
        'IsObjectiveDeterministic', false);
    endTime = results.MinObjective;
    return;
end

function chargingTime = objectiveFunction(params, studyName)
    model = mphopen('BO_SOC50.mph');
    model.param.set('I1', params.I1);
    model.param.set('I2', params.I2);
    model.param.set('I3', params.I3);
    model.param.set('I4', params.I4);
    model.param.set('t1', params.t1);
    model.param.set('t2', params.t2);
    model.param.set('t3', params.t3);
    model.study(studyName).run;

%     eta = mphglobal(model, 'Eta');
%     eta = eta(end,:);
%     chargingTime = mphglobal(model, 'chargetime');
%     chargingTime = chargingTime(end,:);
%     
    if strcmp(studyName, 'std1')
        
        model.result('pg42').run;
        model.result('pg43').run;

        chargingTime = model.result('pg42').feature('glob1').getDouble('xmax');
        disp(['chargingTime = ', num2str(chargingTime)]);
        
        eta = model.result('pg43').feature('glob1').getDouble('ymin');


        etaThreshold = 0;  %%% phis-phil 1 < 1.2[mV]
        maxPenalty = 1e3;
        if eta < etaThreshold
            chargingTime = maxPenalty;
        end
%      if chargingTime < minChargingTimeRef.Value
%         minChargingTimeRef.Value = chargingTime; % 최소 충전 시간 업데이트
        model.param.set('startTime',chargingTime);
     end

    if strcmp(studyName, 'std2')

        model.study('std2').feature('time').set('tlist', 'range(0+startTime, 4, 30000)');
        model.result('pg21').run;
        model.result('pg20').run;

        chargingTime = model.result('pg21').feature('glob1').getDouble('xmax');
        disp(['chargingTime  = ' , num2str(chargingTime)]);

        eta = model.result('pg20').feature('glob1').getDouble('ymin');
        

        etaThreshold = 0;   %%% phis-phil 2 < 8[mV]
        maxPenalty2 = 3e3;

        if eta < etaThreshold
            chargingTime = maxPenalty2;
        end

    end
    
%     if strcmp(studyName, 'std3')
% 
%         model.study('std3').feature('time').set('tlist', 'range(0+startTime, 4, 30000)');
% %         model.study('std3').run
% 
%         model.result('pg39').run;
%         model.result('pg38').run;
% 
%         chargingTime = model.result('pg39').feature('glob1').getDouble('xmax');
%         disp(['chargingTime  = ' , num2str(chargingTime)]);
% 
%         eta = model.result('pg38').feature('glob1').getDouble('ymin');
%         
% 
%         etaThreshold = 0;   %%% phis-phil 3< 4[mV]
%         maxPenalty3 = 2e3;
%         if eta < etaThreshold
%             chargingTime = maxPenalty3;
%         end
% 
% %         model.param.set('startTime4', chargingTime);
%     end

%     if strcmp(studyName, 'std4')
% 
%         model.study('std3').feature('time').set('tlist', 'range(0+startTime, 4, 30000)');
%         model.study('std3').run
% 
% 
%         model.result('pg41').run;
%         model.result('pg40').run;
% 
%         chargingTime = model.result('pg41').feature('glob1').getDouble('xmax');
%         disp(['chargingTime  = ' , num2str(chargingTime)]);
% 
%         eta = model.result('pg40').feature('glob1').getDouble('ymin');
%         
% 
%         etaThreshold = 0;   %%% phis-phil < 0[V]
%         maxPenalty4 = 3e3;
%         if eta < etaThreshold
%             chargingTime = maxPenalty4;
%          end
%     end

%      if eta > maxEtaRef.Value
%         maxEtaRef.Value = eta;
%         bestVarsRef.Value = params;
%     end
%        

    disp(['Eta  = ' , num2str(eta)]);

end