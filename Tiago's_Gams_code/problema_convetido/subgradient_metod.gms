while(iteracao_grande < 10000 and time_current < time_limit and subdradient_modulo > 0 and UB - LB > 1/10**3 and UB - LB > abs(UB)*1/10**6,
         iteracao_grande := iteracao_grande + 1;
$include "C:\Artigos\p-LD\numerical experiments\v8\problema_convetido\Oraculo.gms"

* subgradient metgod
* recalcula os multiplicadores
         subdradient_modulo := sqrt(sum((i, sc)$domininio_multip(i,sc), power(subgradient(i,sc),2)));
         if (subdradient_modulo > 0,
            tamanho_passo := 2*(UB-LB)/subdradient_modulo**2;
            multiplicadores(i,sc)$domininio_multip(i,sc) := multiplicadores(i,sc) - tamanho_passo * subgradient(i,sc);
         );

*recalcula os tempos
         time_current = TimeElapsed - time_Start;
         if(time_current < time_limit,
                  Rel_lagrange.reslim = time_limit - time_current;
         else
                  Rel_lagrange.reslim = 0;
         );

         display UB, LB, x_stoc_rel, x_stoc_ori, subgradient, valor_fixado, multiplicadores;

         put Results;
         put '----------' /
             'Iteration ', iteracao_grande  /
             'Time elapsed ', time_current  /
             'UB_iteracao ', UB_iteracao /
             'LB_iteracao ', LB_iteracao /
             'UB ', UB /
             'LB ', LB /
             'LB_cut ', cuts_Fo.l
             ;
         putclose;
);



display UB, LB, x_stoc_rel, x_stoc_ori, subgradient, valor_fixado, multiplicadores;