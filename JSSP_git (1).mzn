%-----------------------------------------------------------------------------%
% Università degli studi di Brescia
% Corso di sistemi intelligienti
% Progetto di Mergoni Alberto e Braghini Marco
% 11/04/2024

% job-shop scheduling problem
%-----------------------------------------------------------------------------%

% Parametri

int: n_macchine;                        % Il numero di macchine
int: n_tasks;                           % Il numero di tasks
int: n_jobs_per_task;                   % Numero di job per task
set of int: tasks = 1..n_tasks;
set of int: jobs = 1..n_jobs_per_task;

    % macchine_per_job[task, job] è l'assegnazione delle macchine a ogni job di ogni task.
array [tasks, jobs] of 0..(n_macchine-1): macchine_per_job = [|1,0,2,1,0|1,2,1,2,0|2,1,1,0,1,|2,2,0,1,1,|1,0,1,0,0,|]; 

    % durata_job[task, job] è la durata di ogni job per ogni task.
array [tasks, jobs] of int: durata_jobs = [|5,3,4,3,3|2,6,3,6,1|5,5,5,2,3|5,4,5,3,3|2,6,5,2,6|]; 

%-----------------------------------------------------------------------------%

% Variabili

    % Salvo la durata massima e minima di tutti i job per avere gli estremi del tempo di completamento
int: min_durata = 
    max([sum([durata_jobs[i, j] | j in jobs]) | i in tasks]);

int: max_durata = sum([durata_jobs[i, j] | i in tasks, j in jobs]);

    % Tempo di inizio di ogni job
array [tasks, jobs] of var 0.. max_durata: inizio_jobs;

    % Tempo di fine di ogni job
array [tasks, jobs] of var 0.. max_durata: fine_jobs;

    % Tempo di completamento che corrisponde a quando termina l'ultimo job
var min_durata..max_durata: tempo_completamento;



%-----------------------------------------------------------------------------%
% Constraints

    % i job non possono avere un valore negativo
constraint
    forall ( i in tasks, j in jobs ) (
        durata_jobs[i, j]  >=  0
    );

    % inizio_jobs deve essere un valore maggiore/uguale di 0
constraint
    forall ( i in tasks ) (
        0  <=  inizio_jobs[i, 1]
    );
    
    % Prima di eseguire un job devo aver eseguito tutti quelli prima della stessa task
constraint
    forall ( i in tasks, j in 1..(n_jobs_per_task - 1) ) (
        inizio_jobs[i, j] + durata_jobs[i, j]  <=
            inizio_jobs[i, j + 1]
    );

    % Non possono essere eseguiti più job sulla stessa macchina contemporanteamente
constraint
    forall (
        task_a in tasks,
        task_b in (task_a + 1)..n_tasks,
        job_a, job_b in jobs
    ) (
        if
           macchine_per_job[task_a, job_a]  =  macchine_per_job[task_b, job_b]
        then
               % Non possono partire due job contemporaneamente
            no_overlap( 
                inizio_jobs[task_a, job_a], durata_jobs[task_a, job_a],
                inizio_jobs[task_b, job_b], durata_jobs[task_b, job_b]
            )
        else
            true
        endif
    );
              % Una volta che sto eseguendo un job non posso farne un altro
predicate no_overlap(var int: t_inizio_a, var int: durata_a, var int: t_inizio_b, var int: durata_b)  =
    ( t_inizio_a + durata_a  <=  t_inizio_b )  \/  ( t_inizio_b + durata_b  <=  t_inizio_a );

    % Il tempo di completamento non può essere minore della somma degli intervalli di completamento di ogni job
constraint
    forall ( i in tasks ) (
            inizio_jobs[i, n_jobs_per_task] +
            durata_jobs[i, n_jobs_per_task]
        <=
            tempo_completamento
    );
    
% Il tempo di fine è il tempo di inizio più la durata del job
constraint forall(i in tasks, j in jobs) (
    fine_jobs[i, j] = inizio_jobs[i, j] + durata_jobs[i, j]
);

%-----------------------------------------------------------------------------%
% Cerco la soluzione con il tempo di completamento minore
solve minimize tempo_completamento;

% Stampo il/i risultati
output [
    "Tempo di completamento = ", show(tempo_completamento), "\n",
    "Assegnazione macchine:\n"
] ++
[
    "Task " ++ show(i) ++ ", Job " ++ show(j) ++ ": Macchina " ++ show(macchine_per_job[i,j]) ++ ", Tempo di inizio: " ++ show(inizio_jobs[i,j]) ++ ", Tempo di fine: " ++ show(fine_jobs[i,j]) ++ "\n"
    | i in tasks, j in jobs
];


%-----------------------------------------------------------------------------%