
clear all;
clc;

T1_FREQ = 1000000;
A_T_x100 = 392698;
T1_FREQ_148 = 6760;
A_SQ = 78539749;
A_x20000 = 78;

accel = 100;
speed = 1000;

steps = 50000;

min_delay = 392;               % Minimum delay for a given speed
step_delay = 59908;            % First C0 delay time
steps_2_max_speed = 12820;       % steps_2_max_speed = speed^2 / (2*alpha*accel)


if (steps_2_max_speed == 0) % We need at least 1 step to get to any speed.
    
    steps_2_max_speed = 1;
end

steps_until_decel = uint64(steps * 0.5); % n1 = (n1+n2)decel / (accel + decel)

if (steps_until_decel == 0) % We must accelrate at least 1 steps before we can start deceleration.
    
    steps_until_decel = 1;
end

if (steps_until_decel <= steps_2_max_speed) % We wont reach desired speed
    steps
    steps_until_decel
    decel_val = int64(steps_until_decel) - int64(steps) % n1 - steps  = -n2 ==>> DECEL STEPS
    
    
else % We will reach max speed
    
    decel_val = -steps_2_max_speed; % n1*accel1 = n2*accel2 to get to --> n2 = -n1*(accel1/decel2)
    
end

if (decel_val == 0) % We must decelrate at least 1 steps to stop.
    
    decel_val = -1;
end


decel_start = steps + decel_val; % steps - n2 = number of steps befor me start decelerating


if (step_delay <= min_delay) % If the maximum speed is so low that we dont need to go via accelration state.
    step_delay = min_delay;
    run_state = RUN; % Go straght to run state
    
else % If step_delay (Initial speed) is larger than minimum delay then we accelerate
    
    run_state = 1; % Go to accel state
end

n = 0; % Reset acceleration / deceleration counter. Used in the Cn=cn_1-(4*Cn_1+rest)/(4*n+1)
running = true;


step_count = 0;
rest = 0;
last_accel_delay = 0;
new_step_delay= 0;


data = [];


for inter=1:steps*50
    switch (run_state)
        case 0,
            step_count = 0;
            rest = 0;
            running = false;
            break;
            
        case 1,
            step_count=step_count+1;
            n=n+1; % This is the n in the equations
            new_step_delay = int64(step_delay - ((2 * step_delay + rest) / (4 * n + 1)));
            rest = rem((2 * step_delay + rest),(4 * n + 1));
            
            % STATE CHANGE
            % Check if we should start decelration.
            if (step_count >= decel_start)
                
                % n = decel_val; % Is it not the same already??? NO, decel_val is negative.
                run_state = 3;
                rest = 0;
                % Chech if we hitted max speed.
            elseif (new_step_delay <= min_delay)
                
                last_accel_delay = new_step_delay;
                new_step_delay = min_delay;
                rest = 0;
                run_state = 2;
            end
            
        case 2,
            step_count=step_count+1;
            new_step_delay = min_delay; % I think its not neccesary
            % Check if we should start decelration.
            if (step_count >= decel_start)
                
                % n = decel_val;
                rest = 0;
                % Start decelration with same delay as accel ended with.
                new_step_delay = last_accel_delay;
                run_state = 3;
            end
            
        case 3,
            step_count=step_count+1;
            n=n-1; % Starts out negative and slowly goes positive.
            new_step_delay = int64(step_delay*((4 * n + 1 + rest) / (4 * n + 1 -2)));
            rest = rem((4 * n + 1 + rest),(4 * n + 1 -2));
            % % Check if we at last steps
            if (n <= 0)
                run_state = 0;
            end
    end
    step_delay = new_step_delay;
    data = [data; step_count run_state n new_step_delay];
    
            
end

subplot(3,1,1);
plot(data(:,1),data(:,2));
grid;
title('Run state');
xlabel('step');
ylabel('state');
subplot(3,1,2);
plot(data(:,1),data(:,3));
title('n');
xlabel('step');
ylabel('n');
grid;
subplot(3,1,3);
class(data)
plot(data(:,1),data(:,4));
title('steps per second');
xlabel('step');
ylabel('delay in counts');
grid;