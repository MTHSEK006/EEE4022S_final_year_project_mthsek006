function SDMparametersfromdatasheet()
    % Datasheet-based SDM parameter identification using a genetic algorithm,
    % following the method of Lo Brano et al.
    % =========================================================================
    % 1. DATASHEET STC INPUTS (From Nameplate)
    % =========================================================================
    stc.Voc = 21.6;    % Volts
    stc.Isc = 4.76;    % Amps
    stc.Vmp = 18.0;    % Volts
    stc.Imp = 4.44;    % Amps
    stc.Pmp = 80.0;    % Watts

    % =========================================================================
    % 2. BOUNDS DEFINITION
    % =========================================================================
    % Initial estimations based on paper formulas:
    % Rs_approx  = Voc / Isc
    % Rsh_approx = Vmp / (0.2 * (Isc - Imp))
    Rs_est  = stc.Voc / stc.Isc;
    Rsh_est = stc.Vmp / (0.2 * (stc.Isc - stc.Imp));

    % Decision Vector x = [I_L, I_0, a, R_s, R_sh]
    % Bounds:
    lb = [0.99 * stc.Isc,  1e-12, 0.83, (1/80)*Rs_est,  0.5 * Rsh_est];
    ub = [1.01 * stc.Isc,  1e-8,  3.00, (1/8) *Rs_est,  2.0 * Rsh_est];

    nVars = 5;

    % =========================================================================
    % 3. GENETIC ALGORITHM CONFIGURATION
    % =========================================================================
    popSize    = 500;
    maxGens    = 1500;
    pCrossover = 0.8;
    pMutInd    = 0.2;     % Probability of mutating an individual
    pMutGene   = 0.1;     % Probability of mutating each gene
    eta        = 20;      % Deb polynomial distribution index
    nElite     = 10;      % 2% elitism (10 out of 500)
    kTourn     = 3;       % Tournament size
    eThresh    = 1e-4;    % Error threshold for early stopping
    
    % Stagnation monitoring parameters
    W = 200;              % Window size
    epsilon = 1e-6;       % Tolerance for stagnation
    rho = 0.2;            % Reseed fraction (20%)

    % Initialize Population (Uniform Sampling within Bounds)
    pop = zeros(popSize, nVars);
    for i = 1:nVars
        pop(:, i) = lb(i) + (ub(i) - lb(i)) * rand(popSize, 1);
    end

    fitness = zeros(popSize, 1);
    for i = 1:popSize
        fitness(i) = computeObjective(pop(i, :), stc);
    end

    bestFitHistory = zeros(maxGens, 1);

    % =========================================================================
    % 4. OPTIMIZATION LOOP
    % =========================================================================
    for gen = 1:maxGens
        % Sort population by fitness (ascending order - minimization)
        [fitness, idx] = sort(fitness, 'ascend');
        pop = pop(idx, :);
        bestFitHistory(gen) = fitness(1);

        % --- Stopping Criteria Check ---
        if fitness(1) <= eThresh
            fprintf('Converged at generation %d (Error <= 1e-4)\n', gen);
            break;
        end

        % --- Stagnation Check and Reseed ---
        if gen >= W
            windowMin = min(bestFitHistory(gen-W+1 : gen));
            deltaE = windowMin - fitness(1);
            if deltaE < epsilon && gen > 100
                % Partial Reseed: replace lowest 20% of non-elite with random samples
                nReseed = round(rho * popSize);
                reseedStart = popSize - nReseed + 1;
                for j = reseedStart:popSize
                    for v = 1:nVars
                        pop(j, v) = lb(v) + (ub(v) - lb(v)) * rand();
                    end
                    fitness(j) = computeObjective(pop(j, :), stc);
                end
            end
        end

        % --- Elitism: Preserve Top 10 Individuals ---
        nextPop = zeros(popSize, nVars);
        nextPop(1:nElite, :) = pop(1:nElite, :);

        % --- Selection, Crossover, and Mutation for Offspring ---
        offspringCount = nElite;
        while offspringCount < popSize
            % Tournament Selection (k = 3)
            p1 = tournamentSelect(pop, fitness, kTourn);
            p2 = tournamentSelect(pop, fitness, kTourn);

            % Uniform Swap Crossover (pc = 0.8)
            c1 = p1; c2 = p2;
            if rand() < pCrossover
                for g = 1:nVars
                    if rand() < 0.5
                        c1(g) = p2(g);
                        c2(g) = p1(g);
                    end
                end
            end

            % Polynomial Bounded Mutation (pm = 0.2 individual, pg = 0.1 gene)
            if rand() < pMutInd
                c1 = polynomialMutation(c1, lb, ub, pMutGene, eta);
            end
            if rand() < pMutInd
                c2 = polynomialMutation(c2, lb, ub, pMutGene, eta);
            end

            % Add Offspring
            offspringCount = offspringCount + 1;
            nextPop(offspringCount, :) = c1;
            if offspringCount < popSize
                offspringCount = offspringCount + 1;
                nextPop(offspringCount, :) = c2;
            end
        end

        % Evaluate Offspring Fitness
        pop = nextPop;
        for i = (nElite + 1):popSize
            fitness(i) = computeObjective(pop(i, :), stc);
        end
    end

    % Final Sort
    [fitness, idx] = sort(fitness, 'ascend');
    bestParams = pop(idx(1), :);
    bestError = fitness(1);

    % =========================================================================
    % 5. DISPLAY RESULTS & SIMULATION VALIDATION
    % =========================================================================
    IL   = bestParams(1);
    I0   = bestParams(2);
    a    = bestParams(3);
    Rs   = bestParams(4);
    Rsh  = bestParams(5);

    fprintf('\n================ EXTRACTED PARAMETERS ================\n');
    fprintf('Light-generated current (I_L)     : %.5f A\n', IL);
    fprintf('Diode saturation current (I_0)    : %.5e A\n', I0);
    fprintf('Composite ideality factor (a)     : %.5f V\n', a);
    fprintf('Series resistance (R_s)           : %.5f Ohms\n', Rs);
    fprintf('Shunt resistance (R_sh)           : %.5f Ohms\n', Rsh);
    fprintf('Final Relative Synthetic Error (E): %.6f\n', bestError);
    fprintf('=====================================================\n\n');

    % Generate full I-V and P-V curves using extracted parameters
    V_sim = linspace(0, stc.Voc * 1.02, 300);
    I_sim = zeros(size(V_sim));
    for k = 1:length(V_sim)
        I_sim(k) = solveSingleDiodeLambertW(V_sim(k), IL, I0, a, Rs, Rsh);
    end
    P_sim = V_sim .* I_sim;

    % Plot I-V & P-V curves vs Datasheet Reference Points
    figure('Color', 'w');
    subplot(2,1,1);
    plot(V_sim, I_sim, 'b-', 'LineWidth', 2); hold on;
    plot([0, stc.Vmp, stc.Voc], [stc.Isc, stc.Imp, 0], 'ro', 'MarkerSize', 8, 'LineWidth', 2);
    grid on; xlabel('Voltage [V]'); ylabel('Current [A]');
    title('Single-Diode Model Fitting: I-V Curve (GSM80W)');
    legend('Simulated Model', 'Datasheet Points', 'Location', 'southwest');

    subplot(2,1,2);
    plot(V_sim, P_sim, 'r-', 'LineWidth', 2); hold on;
    plot(stc.Vmp, stc.Pmp, 'bo', 'MarkerSize', 8, 'LineWidth', 2);
    grid on; xlabel('Voltage [V]'); ylabel('Power [W]');
    title('P-V Curve & Maximum Power Point');
    legend('Simulated Power', 'Datasheet MPP', 'Location', 'northwest');
end

% =========================================================================
% COMPOSITE OBJECTIVE FUNCTION
% =========================================================================
function E = computeObjective(x, stc)
    IL  = x(1);
    I0  = x(2);
    a   = x(3);
    Rs  = x(4);
    Rsh = x(5);

    % Weights
    w_Voc  = 5.0;
    w_Isc  = 1.0;
    w_Vmp  = 1.5;
    w_Imp  = 1.5;
    w_stat = 0.3;

    % 1. Simulated Voc (I = 0)
    Voc_sim = solveVocLambertW(IL, I0, a, Rs, Rsh);

    % 2. Simulated Isc (V = 0)
    Isc_sim = solveSingleDiodeLambertW(0, IL, I0, a, Rs, Rsh);

    % 3. Simulated Current at Vmp*
    Imp_sim = solveSingleDiodeLambertW(stc.Vmp, IL, I0, a, Rs, Rsh);

    % 4. Simulated Voltage at Imp* (Numerical inversion at Imp)
    Vmp_sim = solveVmpLambertW(stc.Imp, IL, I0, a, Rs, Rsh, stc.Vmp);

    % Relative Errors
    e_Voc = abs(Voc_sim - stc.Voc) / stc.Voc;
    e_Isc = abs(Isc_sim - stc.Isc) / stc.Isc;
    e_Vmp = abs(Vmp_sim - stc.Vmp) / stc.Vmp;
    e_Imp = abs(Imp_sim - stc.Imp) / stc.Imp;

    % 5. Stationarity Condition
    I_vmp = solveSingleDiodeLambertW(stc.Vmp, IL, I0, a, Rs, Rsh);
    argExp = (stc.Vmp + I_vmp * Rs) / a;
    
    % Prevent overflow in exponent
    if argExp > 700, argExp = 700; end
    expTerm = exp(argExp);

    dF_dV = (I0 / a) * expTerm + (1 / Rsh);
    dF_dI = 1 + (I0 * Rs / a) * expTerm + (Rs / Rsh);
    dI_dV = -dF_dV / dF_dI;

    e_stat = abs(I_vmp + stc.Vmp * dI_dV) / stc.Imp;

    % Composite Objective Index
    E = w_Voc*e_Voc + w_Isc*e_Isc + w_Vmp*e_Vmp + w_Imp*e_Imp + w_stat*e_stat;
    
    if isnan(E) || isinf(E)
        E = 1e6;
    end
end

% =========================================================================
% LAMBERT W ANALYTICAL SOLVER FOR CURRENT I(V)
% =========================================================================
function I = solveSingleDiodeLambertW(V, IL, I0, a, Rs, Rsh)
    % Exact Lambert W analytical formulation of single-diode model
    % I = (Rsh*(IL + I0) - V) / (Rs + Rsh) - (a/Rs) * W( theta )
    theta = (I0 * Rs * Rsh / (a * (Rs + Rsh))) * ...
            exp((Rsh * (Rs * (IL + I0) + V)) / (a * (Rs + Rsh)));
    
    % MATLAB built-in lambertw function
    wVal = lambertw(0, real(theta));
    if isnan(wVal) || isinf(wVal)
        I = 0;
        return;
    end
    I = (Rsh * (IL + I0) - V) / (Rs + Rsh) - (a / Rs) * real(wVal);
end

function Voc = solveVocLambertW(IL, I0, a, Rs, Rsh)
    % Analytical solution for Voc (setting I = 0)
    theta = (I0 * Rsh / a) * exp((Rsh * (IL + I0)) / a);
    wVal = lambertw(0, real(theta));
    Voc = Rsh * (IL + I0) - a * real(wVal);
end

function Vmp = solveVmpLambertW(Imp, IL, I0, a, Rs, Rsh, V_init)
    % Find voltage V for a target current Imp
    options = optimset('Display', 'off', 'TolX', 1e-6);
    fun = @(V) solveSingleDiodeLambertW(V, IL, I0, a, Rs, Rsh) - Imp;
    try
        Vmp = fzero(fun, V_init, options);
    catch
        Vmp = V_init;
    end
end

% =========================================================================
% GA OPERATORS
% =========================================================================
function parent = tournamentSelect(pop, fitness, k)
    idx = randi(length(fitness), [k, 1]);
    [~, bestIdx] = min(fitness(idx));
    parent = pop(idx(bestIdx), :);
end

function child = polynomialMutation(parent, lb, ub, pMutGene, eta)
    child = parent;
    nVars = length(parent);
    for j = 1:nVars
        if rand() < pMutGene
            xl = lb(j);
            xu = ub(j);
            x = child(j);
            r = rand();
            if r < 0.5
                delta_q = (2*r)^(1/(1+eta)) - 1;
            else
                delta_q = 1 - (2*(1-r))^(1/(1+eta));
            end
            x_mut = x + delta_q * (xu - xl);
            % Enforce boundaries
            child(j) = max(xl, min(xu, x_mut));
        end
    end
end