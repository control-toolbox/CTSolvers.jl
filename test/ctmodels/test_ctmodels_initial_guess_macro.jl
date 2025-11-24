function test_ctmodels_initial_guess_macro()

	ocp_fixed = @def begin
		t ∈ [0, 1], time
		x = (q, v) ∈ R², state
		u ∈ R, control
		x(0) == [-1, 0]
		x(1) == [0, 0]
		ẋ(t) == [v(t), u(t)]
		∫(0.5u(t)^2) → min
	end

	ocp_var = @def begin
		tf ∈ R,          variable
		t ∈ [0, tf],     time
		x = (q, v) ∈ R², state
		u ∈ R,           control
		-1 ≤ u(t) ≤ 1
		q(0)  == -1
		v(0)  == 0
		q(tf) == 0
		v(tf) == 0
		ẋ(t) == [v(t), u(t)]
		tf → min
	end

	ocp_var2 = @def begin
		w = (tf, a) ∈ R², variable
		t ∈ [0, 1],       time
		x ∈ R,            state
		u ∈ R,            control
		ẋ(t) == u(t)
		(tf + a) → min
	end

	Test.@testset "ctmodels/initial_guess_macro: minimal control function on fixed-horizon OCP" verbose=VERBOSE showtiming=SHOWTIMING begin
		ig = @init ocp_fixed begin
			u(t) := t
		end
	
		Test.@test ig isa CTSolvers.AbstractOptimalControlInitialGuess
		CTSolvers.validate_initial_guess(ocp_fixed, ig)

		ufun = CTSolvers.control(ig)
		u0 = ufun(0.0)
		u1 = ufun(1.0)

		Test.@test u0 ≈ 0.0
		Test.@test u1 ≈ 1.0
	end

	Test.@testset "ctmodels/initial_guess_macro: simple alias constant on fixed-horizon OCP" verbose=VERBOSE showtiming=SHOWTIMING begin
		ig = @init ocp_fixed begin
			a = 1.0
			v(t) := a
		end
	
		Test.@test ig isa CTSolvers.AbstractOptimalControlInitialGuess
		CTSolvers.validate_initial_guess(ocp_fixed, ig)

		xfun = CTSolvers.state(ig)
		x0 = xfun(0.0)
		x1 = xfun(1.0)

		Test.@test x0[2] ≈ 1.0
		Test.@test x1[2] ≈ 1.0
	end

	Test.@testset "ctmodels/initial_guess_macro: simple alias for variable on variable-horizon OCP" verbose=VERBOSE showtiming=SHOWTIMING begin
		ig = @init ocp_var begin
			a = 1.0
			tf := a
		end
	
		Test.@test ig isa CTSolvers.AbstractOptimalControlInitialGuess
		CTSolvers.validate_initial_guess(ocp_var, ig)
	end

	Test.@testset "ctmodels/initial_guess_macro: 2D variable block and components" verbose=VERBOSE showtiming=SHOWTIMING begin
		# Bloc complet
		ig_block = @init ocp_var2 begin
			w := [1.0, 2.0]
		end
		Test.@test ig_block isa CTSolvers.AbstractOptimalControlInitialGuess
		CTSolvers.validate_initial_guess(ocp_var2, ig_block)
		v_block = CTSolvers.variable(ig_block)
		Test.@test length(v_block) == 2
		Test.@test v_block[1] ≈ 1.0
		Test.@test v_block[2] ≈ 2.0

		# Uniquement la composante tf
		ig_tf = @init ocp_var2 begin
			tf := 1.0
		end
		Test.@test ig_tf isa CTSolvers.AbstractOptimalControlInitialGuess
		CTSolvers.validate_initial_guess(ocp_var2, ig_tf)
		v_tf = CTSolvers.variable(ig_tf)
		Test.@test length(v_tf) == 2
		Test.@test v_tf[1] ≈ 1.0
		Test.@test v_tf[2] ≈ 0.1

		# Uniquement la composante a
		ig_a = @init ocp_var2 begin
			a := 0.5
		end
		Test.@test ig_a isa CTSolvers.AbstractOptimalControlInitialGuess
		CTSolvers.validate_initial_guess(ocp_var2, ig_a)
		v_a = CTSolvers.variable(ig_a)
		Test.@test length(v_a) == 2
		Test.@test v_a[1] ≈ 0.1
		Test.@test v_a[2] ≈ 0.5

		# Deux composantes
		ig_both = @init ocp_var2 begin
			tf := 1.0
			a  := 0.5
		end
		Test.@test ig_both isa CTSolvers.AbstractOptimalControlInitialGuess
		CTSolvers.validate_initial_guess(ocp_var2, ig_both)
		v_both = CTSolvers.variable(ig_both)
		Test.@test length(v_both) == 2
		Test.@test v_both[1] ≈ 1.0
		Test.@test v_both[2] ≈ 0.5
	end

	Test.@testset "ctmodels/initial_guess_macro: per-component functions on fixed-horizon OCP" verbose=VERBOSE showtiming=SHOWTIMING begin
		ig = @init ocp_fixed begin
			q(t) := sin(t)
			v(t) := 1.0
			u(t) := t
		end
	
		Test.@test ig isa CTSolvers.AbstractOptimalControlInitialGuess
		CTSolvers.validate_initial_guess(ocp_fixed, ig)

		xfun = CTSolvers.state(ig)
		ufun = CTSolvers.control(ig)

		x0 = xfun(0.0)
		x1 = xfun(1.0)
		u0 = ufun(0.0)
		u1 = ufun(1.0)

		Test.@test x0[1] ≈ sin(0.0)
		Test.@test x1[1] ≈ sin(1.0)
		Test.@test x0[2] ≈ 1.0
		Test.@test x1[2] ≈ 1.0
		Test.@test u0 ≈ 0.0
		Test.@test u1 ≈ 1.0
	end

	Test.@testset "ctmodels/initial_guess_macro: state block function on fixed-horizon OCP" verbose=VERBOSE showtiming=SHOWTIMING begin
		ig = @init ocp_fixed begin
			x(t) := [sin(t), 1.0]
			u(t) := t
		end
	
		Test.@test ig isa CTSolvers.AbstractOptimalControlInitialGuess
		CTSolvers.validate_initial_guess(ocp_fixed, ig)

		xfun = CTSolvers.state(ig)
		ufun = CTSolvers.control(ig)

		x0 = xfun(0.0)
		x1 = xfun(1.0)
		u0 = ufun(0.0)
		u1 = ufun(1.0)

		Test.@test x0[1] ≈ sin(0.0)
		Test.@test x1[1] ≈ sin(1.0)
		Test.@test x0[2] ≈ 1.0
		Test.@test x1[2] ≈ 1.0
		Test.@test u0 ≈ 0.0
		Test.@test u1 ≈ 1.0
	end

	Test.@testset "ctmodels/initial_guess_macro: block time-grid init on fixed-horizon OCP" verbose=VERBOSE showtiming=SHOWTIMING begin
		T = [0.0, 0.5, 1.0]
		X = [[-1.0, 0.0], [0.0, 0.5], [0.0, 0.0]]
		U = [0.0, 0.0, 1.0]

		ig = @init ocp_fixed begin
			x(T) := X
			u(T) := U
		end
	
		Test.@test ig isa CTSolvers.AbstractOptimalControlInitialGuess
		CTSolvers.validate_initial_guess(ocp_fixed, ig)

		xfun = CTSolvers.state(ig)
		ufun = CTSolvers.control(ig)

		x0 = xfun(0.0)
		x1 = xfun(1.0)
		u0 = ufun(0.0)
		u1 = ufun(1.0)

		Test.@test x0[1] ≈ -1.0
		Test.@test x0[2] ≈ 0.0
		Test.@test x1[1] ≈ 0.0
		Test.@test x1[2] ≈ 0.0
		Test.@test u0 ≈ 0.0
		Test.@test u1 ≈ 1.0
	end

	Test.@testset "ctmodels/initial_guess_macro: block matrix time-grid init on fixed-horizon OCP" verbose=VERBOSE showtiming=SHOWTIMING begin
		T = [0.0, 0.5, 1.0]
		Xmat = [-1.0 0.0;
		        0.0 0.5;
		        0.0 0.0]
		U = [0.0, 0.0, 1.0]

		ig = @init ocp_fixed begin
			x(T) := Xmat
			u(T) := U
		end
	
		Test.@test ig isa CTSolvers.AbstractOptimalControlInitialGuess
		CTSolvers.validate_initial_guess(ocp_fixed, ig)

		xfun = CTSolvers.state(ig)
		ufun = CTSolvers.control(ig)

		x0 = xfun(0.0)
		x1 = xfun(1.0)
		u0 = ufun(0.0)
		u1 = ufun(1.0)

		Test.@test x0[1] ≈ -1.0
		Test.@test x0[2] ≈ 0.0
		Test.@test x1[1] ≈ 0.0
		Test.@test x1[2] ≈ 0.0
		Test.@test u0 ≈ 0.0
		Test.@test u1 ≈ 1.0
	end

	Test.@testset "ctmodels/initial_guess_macro: block (T, nothing) init on fixed-horizon OCP" verbose=VERBOSE showtiming=SHOWTIMING begin
		T = [0.0, 0.5, 1.0]

		ig = @init ocp_fixed begin
			x(T) := nothing
			u(T) := nothing
		end
	
		Test.@test ig isa CTSolvers.AbstractOptimalControlInitialGuess
		CTSolvers.validate_initial_guess(ocp_fixed, ig)
	end

	Test.@testset "ctmodels/initial_guess_macro: component time-grid init on fixed-horizon OCP" verbose=VERBOSE showtiming=SHOWTIMING begin
		Tq = [0.0, 0.5, 1.0]
		Dq = [-1.0, -0.5, 0.0]
		Tv = [0.0, 1.0]
		Dv = [0.0, 0.0]
		Tu = [0.0, 1.0]
		Du = [0.0, 1.0]

		ig = @init ocp_fixed begin
			q(Tq) := Dq
			v(Tv) := Dv
			u(Tu) := Du
		end
	
		Test.@test ig isa CTSolvers.AbstractOptimalControlInitialGuess
		CTSolvers.validate_initial_guess(ocp_fixed, ig)

		xfun = CTSolvers.state(ig)
		ufun = CTSolvers.control(ig)

		x0 = xfun(0.0)
		x1 = xfun(1.0)
		u0 = ufun(0.0)
		u1 = ufun(1.0)

		Test.@test x0[1] ≈ -1.0
		Test.@test x1[1] ≈ 0.0
		Test.@test x0[2] ≈ 0.0
		Test.@test x1[2] ≈ 0.0
		Test.@test u0 ≈ 0.0
		Test.@test u1 ≈ 1.0
	end

	Test.@testset "ctmodels/initial_guess_macro: partial init on fixed-horizon OCP" verbose=VERBOSE showtiming=SHOWTIMING begin
		ig = @init ocp_fixed begin
			q(t) := sin(t)
			v(t) := 1.0
		end
	
		Test.@test ig isa CTSolvers.AbstractOptimalControlInitialGuess
		CTSolvers.validate_initial_guess(ocp_fixed, ig)
	end

	Test.@testset "ctmodels/initial_guess_macro: constant init on fixed-horizon OCP" verbose=VERBOSE showtiming=SHOWTIMING begin
		ig = @init ocp_fixed begin
			q := -1.0
			v := 0.0
			u := 0.1
		end
	
		Test.@test ig isa CTSolvers.AbstractOptimalControlInitialGuess
		CTSolvers.validate_initial_guess(ocp_fixed, ig)
	end

	Test.@testset "ctmodels/initial_guess_macro: variable-only init on variable-horizon OCP" verbose=VERBOSE showtiming=SHOWTIMING begin
		ig = @init ocp_var begin
			tf := 1.0
		end
	
		Test.@test ig isa CTSolvers.AbstractOptimalControlInitialGuess
		CTSolvers.validate_initial_guess(ocp_var, ig)
	end

	Test.@testset "ctmodels/initial_guess_macro: per-component functions on variable-horizon OCP" verbose=VERBOSE showtiming=SHOWTIMING begin
		ig = @init ocp_var begin
			tf := 1.0
			q(t) := sin(t)
			v(t) := 1.0
			u(t) := t
		end
	
		Test.@test ig isa CTSolvers.AbstractOptimalControlInitialGuess
		CTSolvers.validate_initial_guess(ocp_var, ig)

		xfun = CTSolvers.state(ig)
		ufun = CTSolvers.control(ig)

		x0 = xfun(0.0)
		x1 = xfun(1.0)
		u0 = ufun(0.0)
		u1 = ufun(1.0)

		Test.@test x0[1] ≈ sin(0.0)
		Test.@test x1[1] ≈ sin(1.0)
		Test.@test x0[2] ≈ 1.0
		Test.@test u0 ≈ 0.0
		Test.@test u1 ≈ 1.0
	end

	Test.@testset "ctmodels/initial_guess_macro: (T, nothing) init on variable-horizon OCP" verbose=VERBOSE showtiming=SHOWTIMING begin
		T = [0.0, 0.5, 1.0]

		ig = @init ocp_var begin
			tf := 1.0
			x(T) := nothing
			u(T) := nothing
		end
	
		Test.@test ig isa CTSolvers.AbstractOptimalControlInitialGuess
		CTSolvers.validate_initial_guess(ocp_var, ig)
	end

	Test.@testset "ctmodels/initial_guess_macro: block time-grid init on variable-horizon OCP" verbose=VERBOSE showtiming=SHOWTIMING begin
		T = [0.0, 0.5, 1.0]
		X = [[-1.0, 0.0], [0.0, 0.5], [0.0, 0.0]]
		U = [0.0, 0.0, 1.0]

		ig = @init ocp_var begin
			tf := 1.0
			x(T) := X
			u(T) := U
		end
	
		Test.@test ig isa CTSolvers.AbstractOptimalControlInitialGuess
		CTSolvers.validate_initial_guess(ocp_var, ig)

		xfun = CTSolvers.state(ig)
		ufun = CTSolvers.control(ig)

		x0 = xfun(0.0)
		x1 = xfun(1.0)
		u0 = ufun(0.0)
		u1 = ufun(1.0)

		Test.@test x0[1] ≈ -1.0
		Test.@test x0[2] ≈ 0.0
		Test.@test x1[1] ≈ 0.0
		Test.@test x1[2] ≈ 0.0
		Test.@test u0 ≈ 0.0
		Test.@test u1 ≈ 1.0
	end

	Test.@testset "ctmodels/initial_guess_macro: component time-grid init on variable-horizon OCP" verbose=VERBOSE showtiming=SHOWTIMING begin
		Tq = [0.0, 0.5, 1.0]
		Dq = [-1.0, -0.5, 0.0]
		Tv = [0.0, 1.0]
		Dv = [0.0, 0.0]
		Tu = [0.0, 1.0]
		Du = [0.0, 1.0]

		ig = @init ocp_var begin
			tf := 1.0
			q(Tq) := Dq
			v(Tv) := Dv
			u(Tu) := Du
		end
	
		Test.@test ig isa CTSolvers.AbstractOptimalControlInitialGuess
		CTSolvers.validate_initial_guess(ocp_var, ig)

		xfun = CTSolvers.state(ig)
		ufun = CTSolvers.control(ig)

		x0 = xfun(0.0)
		x1 = xfun(1.0)
		u0 = ufun(0.0)
		u1 = ufun(1.0)

		Test.@test x0[1] ≈ -1.0
		Test.@test x1[1] ≈ 0.0
		Test.@test x0[2] ≈ 0.0
		Test.@test x1[2] ≈ 0.0
		Test.@test u0 ≈ 0.0
		Test.@test u1 ≈ 1.0
	end

	Test.@testset "ctmodels/initial_guess_macro: invalid component vector without time (fixed horizon)" verbose=VERBOSE showtiming=SHOWTIMING begin
		Test.@test_throws CTBase.IncorrectArgument @init ocp_fixed begin
			q := [0.0, 1.0]
		end
	end
	
	Test.@testset "ctmodels/initial_guess_macro: time-grid length mismatch on component (fixed horizon)" verbose=VERBOSE showtiming=SHOWTIMING begin
		T = [0.0, 0.5, 1.0]
		Dq_bad = [-1.0, 0.0]
	
		Test.@test_throws CTBase.IncorrectArgument @init ocp_fixed begin
			q(T) := Dq_bad
		end
	end
	
	Test.@testset "ctmodels/initial_guess_macro: mixing state block and component (fixed horizon)" verbose=VERBOSE showtiming=SHOWTIMING begin
		Test.@test_throws CTBase.IncorrectArgument @init ocp_fixed begin
			x(t) := [sin(t), 1.0]
			q(t) := 0.0
		end
	end
	
	Test.@testset "ctmodels/initial_guess_macro: unknown component name (fixed horizon)" verbose=VERBOSE showtiming=SHOWTIMING begin
		Test.@test_throws CTBase.IncorrectArgument @init ocp_fixed begin
			z(t) := 1.0
		end
	end
	
	Test.@testset "ctmodels/initial_guess_macro: invalid variable dimension (variable horizon)" verbose=VERBOSE showtiming=SHOWTIMING begin
		Test.@test_throws CTBase.IncorrectArgument @init ocp_var begin
			tf := [1.0, 2.0]
		end
	end
	
	Test.@testset "ctmodels/initial_guess_macro: time-grid length mismatch on component (variable horizon)" verbose=VERBOSE showtiming=SHOWTIMING begin
		Tq = [0.0, 0.5, 1.0]
		Dq_bad = [-1.0, 0.0]
	
		Test.@test_throws CTBase.IncorrectArgument @init ocp_var begin
			tf := 1.0
			q(Tq) := Dq_bad
		end
	end

end
