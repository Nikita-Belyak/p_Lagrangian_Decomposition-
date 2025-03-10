using Random, LinearAlgebra, SparseArrays

#--------------auxiliary function for generating quadratic matrices for cosnstraints and obejctive with predefined densiity
function quadratic_matrix_generation(density, dimention, min_range, max_range, PSD, seed)

    Random.seed!(seed)

    # if the matrix is supposed to be PSD
    if PSD == "yes"

        # creating the matrix of predefined density,
        # taking into account that this density is defined for the case when a matrix is symmetrical
        # we generate triangular matrix in such a way that if it is represented as a symmetric one
        # (dividing upper triangular part by 2 and reflecting it towards the diagonal)
        # it will have that predefined density

        # separately generating diagonal elements not equal to zero (to be able to create PSD after)
        diagonal_elements  = max_range .* round.(rand(1, dimention), RoundUp, digits = 1)

        # calculating the number of non-zero elements in the upper diagonal part
        # depending on the predefined density
        # and taking into account that diagonal elements are non-zero
        number_of_other_non_zero_elements = max(0,  Int(round((density * dimention^2 - dimention) / 2)))

        # creating one-dimensional array containing an abovementioned number of non zero elements,
        # filling the rest with zeros and shuffling the array
        upper_triangular_elements  = shuffle!([(min_range .+ (max_range - min_range) .* round.(rand(1, number_of_other_non_zero_elements), digits = 1 )) zeros(1, Int(dimention*(dimention-1)/2) - number_of_other_non_zero_elements) ] )

        # creating final matrix with zero elements
        Q = zeros(dimention, dimention)

        # using above mentioned diagonal elements and upper triangular part
        # rewriting zeros in the upper triangular part accordingly
        for i = 1:dimention
            for j = i:dimention
                if i == j # if the element is on the diagonal using an array of diagonal elements
                    Q[i,i] = diagonal_elements[i]
                else
                    Q[i,j] = upper_triangular_elements[1]/2 # otherwise using one elemnts from upper triangular elements
                    Q[j,i] = upper_triangular_elements[1]/2 # otherwise using one elemnts from upper triangular elements
                    upper_triangular_elements = upper_triangular_elements[2:end] # deleting that element from the set
                end
            end
        end

        # if the matrix is supposed to be a PSD then check if the diagonal elements are bigger
        # than the sum of the elements on the same row and if it's not the case increase it by
        # a bigger enough number
        for i = 1:dimention
            #Q[i,i] = Q[i,i] > sum(Q[i,i+1:end]) ? Q[i,i] : sum(Q[i,i+1:end]) + 1
            Q[i,i] = Q[i,i] > (sum(abs.(Q[i, 1:i-1])) + sum(abs.(Q[i, i+1:end]))) ? Q[i,i] : (sum(abs.(Q[i, 1:i-1])) + sum(abs.(Q[i, i+1:end]))) +1000
        end
    # if the matrix does not have to be necessarily PSD
    else
        Q = (min_range  + (max_range - min_range) ) .* Matrix(Symmetric(sprand(dimention,dimention,density)))
    end

    return Q
end

#--------------function for generation the parameters---------------------------

function parameters_generation(number_of_scenarios, number_of_integer_decision_variables, number_of_continuous_decision_variables, number_of_constraints, Qdensity, seed)

        Random.seed!(seed)

        Max_value_for_matrix_elements = 100
        Min_value_for_matrix_elements = 0

        Max_value_for_affine_constraint = 10000000

        x_limits = [0 100] # max and min values for the continuous variables' boundaries
        y_limits = [0 100] # max and min values for the integer variables' boundaries


        #---------------generating constraints for the variables------------------------

        x_boundaries = [ x_limits[1]*ones( number_of_integer_decision_variables, 1 ) rand(
            Int( round( (x_limits[2] - x_limits[1]) / 2 ) ) : x_limits[2],
            number_of_integer_decision_variables, 1 ) ]

        y_boundaries = [ y_limits[1]*ones( number_of_continuous_decision_variables, 1 ) rand(
            Int( round( (y_limits[2] - y_limits[1]) / 2 ) ) : y_limits[2],
            number_of_continuous_decision_variables, 1 ) ]

        #---------------generating quadratic constraints for the scenarios--------------

        # generating matrices Qsi for the left hand side of the contraint for each of the scenario
        constraint_Qs = Array{Any}(undef, 1, number_of_scenarios)

        [ constraint_Qs[i] = [ quadratic_matrix_generation(Qdensity, number_of_continuous_decision_variables, Min_value_for_matrix_elements, Max_value_for_matrix_elements, "no", seed)
            for j = 1 : number_of_constraints] for i = 1:number_of_scenarios ]

        # generating affine functions' coefficients for the left hand side of the constraint for each of the scenario
        constraint_fs = Array{Any}(undef, 1, number_of_scenarios)

        [ constraint_fs[i] = [ round.([(Min_value_for_matrix_elements + (Max_value_for_matrix_elements - Min_value_for_matrix_elements)) .* [rand(1, number_of_integer_decision_variables) zeros(1, ( number_of_continuous_decision_variables > number_of_integer_decision_variables ) ? (number_of_continuous_decision_variables - number_of_integer_decision_variables) : 0 ) ];
                                (Min_value_for_matrix_elements + (Max_value_for_matrix_elements - Min_value_for_matrix_elements)) .* [ rand(1, number_of_continuous_decision_variables) zeros(1, ( number_of_integer_decision_variables > number_of_continuous_decision_variables ) ? (number_of_integer_decision_variables - number_of_continuous_decision_variables) : 0 ) ];
                                -Max_value_for_affine_constraint .* [rand(1,1) zeros(1, ( number_of_continuous_decision_variables > number_of_integer_decision_variables ) ? (number_of_continuous_decision_variables - 1) : (number_of_integer_decision_variables - 1))] ], digits = 1)
            for j = 1:number_of_constraints] for i = 1:number_of_scenarios ]
        # first row - x_coeficients (integer variables)
        # second row - y_coeficients (continuous variables)
        # third row  - constant

        #---------------generating obejctive fucntions for the scenarios----------------

        # generating matrices Qsi for the objecyive for each of the scenario
        objective_Qs = Array{Any}(undef, 1, number_of_scenarios)

        [ objective_Qs[i] = quadratic_matrix_generation(Qdensity, number_of_continuous_decision_variables, Min_value_for_matrix_elements, Max_value_for_matrix_elements, "no", seed)
        for i = 1:number_of_scenarios ]

        # generating linear functions' coefficients for the objective for each of the scenario
        objective_fs = Array{Any}(undef, 1, number_of_scenarios)

        [ objective_fs[i] = round.( Min_value_for_matrix_elements .+ (Max_value_for_matrix_elements - Min_value_for_matrix_elements) .*  rand(1, number_of_continuous_decision_variables),  digits = 1) for i = 1:number_of_scenarios  ]
        # first row - x_coeficients (continuous variables)
        # second row - y_coeficients (iteger variables)

        objective_c = round.( Min_value_for_matrix_elements .+ (Max_value_for_matrix_elements - Min_value_for_matrix_elements) .*  rand(1, number_of_integer_decision_variables),  digits = 1)
        return [constraint_Qs, constraint_fs, objective_Qs, objective_fs, objective_c, x_boundaries, y_boundaries]
end
