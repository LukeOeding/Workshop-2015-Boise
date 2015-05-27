newPackage("NCAlgebraV2",
     Headline => "Additional functions for NCAlgebra",
     Version => "0.1",
     Date => "January 6th, 2014",
     Authors => {
	  {Name => "Frank Moore",
	   HomePage => "http://www.math.wfu.edu/Faculty/Moore.html",
	   Email => "moorewf@wfu.edu"},
	  {Name => "Andrew Conner",
	   HomePage => "http://www.math.wfu.edu/Faculty/Conner.html",
	   Email => "connerab@wfu.edu"},
          {Name => "Courtney Gibbons",
	   HomePage => "http://people.hamilton.edu/cgibbons",
	   Email => "crgibbon@hamilton.edu"}},
     AuxiliaryFiles => true,
     DebuggingMode => true
     )

export {NCModule,
        degreeList,
	isNCModule,
	homologyAsCokernel,
	identityMap,
	subquotientAsCokernel,
	NCChainComplex,
	qTensorProduct,
	freeProduct,
	--- Anick methods
	edgesAnick,
	nChains}

debug needsPackage "NCAlgebra"

-----------------------------------------------------------------------------
-- NCModule definitions

NCModule = new Type of ImmutableType
new NCModule from List := (NCModule,v) -> new NCModule of Vector from hashTable v
new NCModule from Sequence := (NCModule,x) -> (
     (R,rM) -> (
          assert instance(R,NCRing);
          assert instance(rM,ZZ);
          new NCModule of Vector from hashTable {
                    symbol cache => new CacheTable,
--                    symbol RawFreeModule => rM,
                    symbol ring => R,
                    symbol numgens => rM,
		    symbol degreeList => apply(rM, i-> 0)
                    })) x

NCRing ^ ZZ :=  (R,n) -> R^(apply(n,i-> 0))

NCRing ^ List := (R,L) -> (
   n := #L;
   Mparts := {
          symbol cache => new CacheTable,
--          symbol RawFreeModule => rE,
          symbol ring => R,
          symbol numgens => n,
	  symbol degreeList => L 
          };
   new NCModule of Vector from hashTable Mparts     
)

subquotient(Nothing,NCMatrix) := (null,relns) -> (
     R := ring relns;
--     E := target relns;
     n := #relns.target;
--     rE := E.RawFreeModule;
     Mparts := {
          symbol cache => new CacheTable,
--          symbol RawFreeModule => rE,
          symbol ring => R,
          symbol numgens => n,
	  symbol degreeList => relns.target
          };
--     relns = align matrix relns;    -- if we start having problems with homogenaity we might want to revisit this
{*
     if E.?generators then (
          Mparts = append(Mparts, symbol generators => E.generators);
          relns = E.generators * relns;
          );
     if E.?relations then relns = relns | E.relations;
*}
     if relns != 0 then (
          Mparts = append(Mparts, symbol relations => relns);
          );
     new NCModule of Vector from hashTable Mparts)

subquotient(NCMatrix,Nothing) := (subgens,null) -> (
     R := ring subgens;
--     E := target subgens;
     n := #subgens.target;
--     rE := E.RawFreeModule;
--     subgens = align matrix subgens;
--     if E.?generators then subgens = E.generators * subgens;
     Mparts := {
          symbol cache => new CacheTable,
--          symbol RawFreeModule => rE,
          symbol ring => R,
          symbol numgens => n,
	  symbol degreeList => subgens.target,
          symbol generators => subgens
          };
{*
     if E.?relations then (
          Mparts = append(Mparts, symbol relations => E.relations);
          );
*}
     new NCModule of Vector from hashTable Mparts)

subquotient(NCMatrix,NCMatrix) := (subgens,relns) -> (
     R := ring relns;
--     E := subgens.target;
--     if E != relns.target then error "expected maps with the same target"; -- we used to have =!=, but Schreyer orderings of free modules are discarded by "syz"
--     rE := E.RawFreeModule;
--     n := E.numgens;
     if subgens.target != relns.target then error "expected maps with the same target";
     n := #subgens.target;
     if n == 0 then new NCModule from (R,n)
     else (
{*
--          relns = align matrix relns;
--          subgens = align matrix subgens;
          if E.?generators then (
               relns = E.generators * relns;
               subgens = E.generators * subgens;
               );
          if E.?relations then relns = relns | E.relations;
*}
          Mparts := {
               symbol cache => new CacheTable,
--               symbol RawFreeModule => rE,
               symbol ring => R,
               symbol numgens => n,
	       symbol degreeList => subgens.target,
               symbol generators => subgens
               };
          if relns != 0 then (
               Mparts = append(Mparts, symbol relations => relns);
               );
          new NCModule of Vector from hashTable Mparts))

-- The following checks will go in when NCMatrices have modules as source and target.

subquotient(NCModule,NCMatrix,NCMatrix) := (F,g,r) -> (
     if F =!= target g or F =!= target r then error "expected module to be target of maps";
     subquotient(g,r))
subquotient(NCModule,Nothing,NCMatrix) := (F,g,r) -> (
     if F =!= target r then error "expected module to be target of maps";
     subquotient(g,r))
subquotient(NCModule,NCMatrix,Nothing) := (F,g,r) -> (
     if F =!= target g then error "expected module to be target of maps";
     subquotient(g,r))
subquotient(NCModule,Nothing,Nothing) := (F,g,r) -> F

isNCModule = method(TypicalValue => Boolean)
isNCModule Thing := M -> false
isNCModule Module := M -> false
isNCModule NCModule := M -> true

isFreeModule NCModule := M -> not M.?relations and not M.?generators

isSubmodule NCModule := M -> not M.?relations

isQuotientModule NCModule := M -> not M.?generators

{*
NCModule == NCModule := (M,N) -> (
     ring M === ring N
     and degrees ambient M === degrees ambient N
     and (
          if M.?relations 
          then N.?relations and (
               -- if isHomogeneous N.relations and isHomogeneous M.relations
               -- then gb N.relations == gb M.relations
               -- else 
                    (
                    -- temporary
                    isSubset(image M.relations, image N.relations)
                    and
                    isSubset(image N.relations, image M.relations)
                    )
               )
               else not N.?relations
          )
     and (
	  if M.?generators then (
               if N.?generators then (
                    f := (
                         if M.?relations 
                         then M.relations|M.generators
                             else M.generators);
                    g := (
                         if N.?relations
                         then N.relations|N.generators
                         else N.generators);
                    -- if isHomogeneous f and isHomogeneous g
                    -- then gb f == gb g
                    -- else 
                         (
                         -- temporary
                             isSubset(image f, image g)
                             and
                             isSubset(image g, image f)
                         )
                    )
               else (
                    f = (
                         if M.?relations
                         then M.relations|M.generators
                         else M.generators
                         );
                    if isHomogeneous f then f = substitute(f,0);
                    isSubset(ambient N, image f)))
          else (
               if N.?generators then (
                    g = (
                         if N.?relations 
                         then N.relations|N.generators 
                         else N.generators
                         );
                    if isHomogeneous g then g = substitute(g,0);
                    isSubset(ambient M, image g))
               else true)))
*}
basis (ZZ, NCModule) := (d,M) -> (
   -- the basis is the cokernel of the degree d part of the presentation matrix
   P := if M.cache.?presentation then M.cache.presentation else presentation M;
   degdP := P_d;
   
)

----------------------------------------------------------------------------

freeProduct = method()
freeProduct (NCRing,NCRing) := (A,B) -> (
   R := coefficientRing A;
   if R =!= (coefficientRing B) then error "Input rings must have same coefficient ring.";
   gensA := gens A;
   gensB := gens B;
   newgens := gensA | gensB;     
   if #unique(newgens) != (#gensA + #gensB) then error "Input rings have a common generator.";

   I := gens ideal A;
   J := gens ideal B;
   
   A' := if class A === NCPolynomialRing then A else ambient A;
   B' := if class B === NCPolynomialRing then B else ambient B;
    
   C := R newgens;
   gensAinC := take(gens C, #gensA);
   gensBinC := drop(gens C, #gensA);
   incA := ncMap(C,A',gensAinC);
   incB := ncMap(C,B',gensBinC);
   IinC := I / incA;
   JinC := J / incB;
   newIdealGens := select( (IinC | JinC), x -> x!=0);       
   if newIdealGens == {} then C 
   else C/(ncIdeal newIdealGens)
)

qTensorProduct = method()
qTensorProduct (NCRing, NCRing, QQ) :=
qTensorProduct (NCRing, NCRing, RingElement) := (A,B,q) -> (
   -- this is the q-commuting tensor product of rings
   R := coefficientRing A;
   if class q =!= QQ and q.ring =!= R then error "Twisting parameter must belong to coefficient ring.";
   F := freeProduct(A,B);
   gensAinF := take(gens F, #gens A);
   gensBinF := drop(gens F, #gens A);   
   -- create the commutation relations among generators of A and B
   K := flatten apply( gensAinF, g-> apply( gensBinF, h-> h*g-q*g*h));

   if class F === NCPolynomialRing then F/(ncIdeal K)
   else (
      I := gens ideal F;
      C := ambient F;
      newI := ncIdeal select( (I | K), g -> g!=0);
      C/newI
   )
     
)

NCRing ** NCRing := (A,B) -> (
   qTensorProduct(A,B,promote(1,coefficientRing A))
)

envelopingAlgebra = method()
envelopingAlgebra (NCRing, Symbol) := (A,x) -> (
   --  want to add an option to index op variables by number rather than a ring element?
   R := coefficientRing A;
   Aop := oppositeRing A;
   B := R apply(#gens A, g-> x_g);  -- remove # once indexing works without printing ( ) 
   if class A === NCPolynomialRing then (B ** A) 
   else (
      A' := ambient Aop;   
      f := ncMap(B,A',gens B);
      J := ncIdeal (gens ideal Aop / f);
      (B/J) ** A
   )
)

TEST ///
quit
restart
needsPackage "NCAlgebraV2"
debug needsPackage "NCAlgebra"
A = QQ{a,b,c}
I = ncIdeal{a*b-c^2}
Igb = ncGroebnerBasis(I,InstallGB=>true)
C=A/I
B = QQ{x,y,z}
D = C ** B
e(A,s)
e(C,t)
///

presentation NCModule := M -> (
   if M.cache.?presentation then M.cache.presentation 
   else M.cache.presentation = (
	if M.?generators then 
           subquotientAsCokernel(M.generators,M.relations)    
        else M.relations)
)

subquotientAsCokernel = method()
subquotientAsCokernel (NCMatrix, NCMatrix) := (M,N) -> (
   --- following Algorithm 6.3.1 in Boehm
   L := M | N;
   kerL := rightKernelBergman(L);
   rowsMN := #(M.source);
   tempKer := rightMingens (kerL^(toList(0..(rowsMN-1))));
   tempKer
)

homologyAsCokernel = method()
homologyAsCokernel(NCMatrix,NCMatrix) := (M,N) -> (
    if M*N != 0 then return "Error: maps do not compose to zero"
    else (
    B := N.ring;
    Z := Z = zeroMap((N.target),(N.source),B); -- What is this for?
    kerM := rightKernelBergman(M);
    subquotientAsCokernel(kerM,N)
    )
)

TEST ///
restart
needsPackage "NCAlgebraV2"
debug needsPackage "NCAlgebra"
B = threeDimSklyanin(QQ,{1,1,-1},{x,y,z})
M = ncMatrix {{x^2,y^2,z^3}}
Msyz = rightKernelBergman M
test = subQuotientAsCokernel(Msyz,Msyz)

N = rightKernelBergman(M)
L = transpose ncMatrix{(entries transpose N)_0,(entries transpose N)_1}
L = assignDegrees (L, N.target, N.source)
L.target
isHomogeneous L
M*L == 0
L
M
T = rightKernelBergman(M) | L
isHomogeneous T
rightKernelBergman(T)

homologyAsCokernel(M,N)
homologyAsCokernel(M,L)
///

--NCMatrix ** Matrix := 
--Matrix ** NCMatrix := 
-- what does this matrix represent?
NCMatrix ** NCMatrix := (M,N) -> (
   entriesM := entries M;
   MtensN := ncMatrix applyTable(entriesM, e -> e*N);
   --- now we must assignDegrees to make make them compatible
   --- with the maps M and N
   newSource := flatten apply(#(M.source), i ->
         apply(#(N.source), j -> ((M.source)#i)+((N.source)#j)));
   newTarget := flatten apply(#(M.target), i ->
         apply(#(N.target), j -> ((M.target)#i)+((N.target)#j)));
   assignDegrees(MtensN,newTarget,newSource)
)

NCMatrix ++ NCMatrix := (M,N) -> (
   B := ring M;
   Mtar := M.target;
   Msrc := M.source;
   Ntar := N.target;
   Nsrc := N.source;
   urZero := zeroMap(Mtar,Nsrc,B);
   lrZero := zeroMap(Ntar,Msrc,B);
   -- this is a hack until ncMatrix can take lists of empty matrices
   if Msrc == {} and Mtar == {} then N
   else if Msrc == {} and Nsrc == {} then ncMatrix(B,Mtar|Ntar,{})
   else if Msrc == {} and Ntar == {} then urZero
   else if Msrc == {} then ncMatrix{{urZero},{N}}
   else if Mtar == {} and Nsrc == {} then lrZero
   else if Mtar == {} and Ntar == {} then ncMatrix(B,{},Msrc|Nsrc)
   else if Mtar == {} then ncMatrix{{lrZero,N}}
   else if Nsrc == {} and Ntar == {} then M
   else if Nsrc == {} then ncMatrix{{M},{lrZero}}
   else if Ntar == {} then ncMatrix{{M,urZero}}
   else (
      ds := ncMatrix {{M,urZero},{lrZero,N}};
      assignDegrees(ds,M.target | N.target, M.source | N.source)
   )
)

-------------------------------------------
--- NCChainComplex Methods ----------------
-------------------------------------------
NCChainComplex = new Type of HashTable

resolution NCMatrix := opts -> M -> (
   i := 0;
   numSyz := if opts#LengthLimit === infinity then numgens ring M - 1 else opts#LengthLimit;
   currentM := M;
   syzList := {M} | while (i < numSyz and currentM != 0) list (
      newM := rightKernelBergman currentM;
      currentM = newM;
      currentM
   ) do i = i+1;
   new NCChainComplex from apply(#syzList, i -> (i,syzList#i))
)

betti NCChainComplex := opts -> C -> (
    len := #C;
    firstbettis := flatten apply(
    	keys (tally (C#0).target), 
    	i -> {(0,(C#0).target,i) => (tally (C#0).target)_i}
    );
    if C#(len-1) == 0 then len = len - 1;
    lastbettis := flatten flatten apply(len, j -> 
	apply(
    	    keys (tally (C#j).source), 
    	    i -> {(j+1,(C#j).source,i) => (tally (C#j).source)_i}
	    )
	);
    L := firstbettis | lastbettis;
    B := new BettiTally from L
)

spots = C -> select(keys C, i -> class i === ZZ and C#i != 0)

net NCChainComplex := C -> (
   s := sort spots C;
   if # s === 0 then "0"
   else (
      a := s#0;
      b := s#-1;
      A := ring C#a;
      mostOfThem := horizontalJoin between(" <-- ", apply(a .. b, i -> stack ((net A) | (net (#(C#i.target)))^1," ",net i)));
      mostOfThem | " <-- " |  stack ((net A) | (net (#(C#b.source)))^1," ",net (b+1))
   )
)

TEST ///
restart
needsPackage "NCAlgebraV2"
needsPackage "NCAlgebra"
B = threeDimSklyanin(QQ,{1,1,-1},{x,y,z})
M = ncMatrix {{x,y,z}}
Mres = res M
betti Mres
N = ncMatrix {{x,y,z^2}}
Nres = res N
betti Nres
--- The resolution of the following NCMatrix has a 0 kernel 
--- in homological degree 2
L = ncMatrix {{x^2,x*z,y}};
Lres = res L
betti Lres
rightKernelBergman(Lres#2)
///

-- Twist --     
NCMatrix Array := (M,n) -> (
    if #n != 1 then return "Error: Please enter a single integer" else
    M**(assignDegrees(ncMatrix {{promote(1,M.ring)}},{-1*n#0},{-1*n#0}))
    )

TEST ///
restart
needsPackage "NCAlgebraV2"
needsPackage "NCAlgebra"
B = threeDimSklyanin(QQ,{1,1,-1},{x,y,z})
M = ncMatrix {{x,y,z}}
M[1]
(M[1]).source
///

identityMap = method()
identityMap (List, NCRing) := (L,R) -> (
   n := #L;
   B := coefficientRing R;
   I := ncMatrix applyTable(entries id_(B^n), e -> promote(e,R));
   assignDegrees(I,L,L)
)

identityMap (ZZ,NCRing) := (n,R) -> identityMap(toList(n:0),R)

zeroMap = method()
zeroMap (List, List, NCRing) := (tar,src,B) -> (
   R := coefficientRing B;
   if tar == {} or src == {} then
      ncMatrix(B,tar,src)
   else (
      myZero := ncMatrix applyTable(entries map(R^#tar,R^#src,0), e -> promote(e,B));
      assignDegrees(myZero,tar,src);
      myZero
   )
)

NCMatrix _ ZZ := (M,d) -> (
   entryTable := apply(#(M.target), i -> apply(#(M.source), j -> (i,j)));
   multTable := applyTable(entryTable, e -> leftMultiplicationMap(M#(e#0)#(e#1), 
	                                                d - (M.source)#(e#1),
                                                        d - (M.target)#(e#0)));
   matrix multTable
)

Hom (ZZ,NCModule,NCModule) := (d,M,N) -> (
   if isFreeModule M then (
      R := M.ring;
      I := identityMap(M.source,R);
      (presentation N) ** (transpose I))
   else 
      Hom(d,presentation M,presentation N)
)

Hom (ZZ,NCMatrix,NCMatrix) := (d,M,N) -> (
   -- This method uses Boehm's Algorithm 6.5.1 from "Computer Algebra: Lecture Notes" 
   -- http://www.mathematik.uni-kl.de/~boehm/lehre/1213_CA/ca.pdf
   --
   -- That algorithm applies to modules over a commutative ring R, 
   -- taking advantage of the fact that Hom(M,N) is an R-module in that case.
   -- In our case, we must work on the level of graded vector spaces, as 
   -- Hom(M,N) need not be an R-module if R is noncommutative
   --
   -- The setup here:
   --
   -- M and N are presentation matrices for a pair of graded modules over an NCRing 
   -- We compute graded homomorphisms only; a degree d homomorphism M --> N is the
   -- same as a degree 0 homomorphism M --> N[d]. The method returns a basis for 
   -- the space of degree d homomorphisms. Each map is represented by a matrix.
   -- The matrix is a lift of the homomorphism to a map between targets of presentation
   -- matrices. That is, if B is the NCRing, a homomorphism from coker M to coker N is
   -- a pair of maps completing the commutative diagram below. We return f as a matrix.
   -- 
   -- coker M <--- B^{s0} <-- M --- B^{s1}
   --    |          |                 |
   --    |          f                 g
   --    |          |                 |
   --	 v	    v                 v
   -- coker N <--- B^{t0} <-- N --- B^{t1} 
   --
   -- The key to implementing Boehm's algorithm is the identification
   -- Hom(B^n, B^m) = B^m \tensor (B^n)*
   -- This identification is valid in the category of locally finite graded modules.
   B := ring M;
   -- it might be cleaner to shift N and set d=0

   -- Step 1: We need the first syzygy module of N to deal with homotopy.
   --
   -- coker M <--- B^{s0} <-- M --- B^{s1}
   --    |          |                 |
   --    |          f                 g
   --    |          |                 |
   --	 v	    v                 v
   -- coker N <--- B^{t0} <-- N --- B^{t1} <---- Nsyz ---- B^{t2}
   
   Nsyz := rightKernelBergman N; 
   if Nsyz == ncMatrix{{promote(0,B)}} then Nsyz = zeroMap(N.source,{0},B);

   -- Step 2: Compute the map "\delta"
   --      Hom(B^{s0},B^{t0}) ++ Hom(B^{s1},B^{t1}) ----> Hom(B^{s1},B^{t0}) 
   --               ( f, g ) |--->  f*M - N*g
   -- since every homomorphism belongs to the kernel of this map. 
   --
   -- After the identifications mentioned above, the map is given by
   --      id \tensor M* - N \tensor id*

   L1 := identityMap(N.target,B); -- identity on B^t0
   L2 := identityMap(M.source,B); -- identity on B^s1
   K1 := L1 ** (transpose M);    
   K2 := N ** (transpose L2);
   
   -- Step 3: Compute the kernel of the map \delta in the prescribed degree
   --
   -- See below.
   --
   -- Step 4: Compute the map "\rho"
   --      Hom(B^{s0},B^{t1}) ++ Hom(B^{s1},B^{t2}) ----> Hom(B^{s0},B^{t0}) ++ Hom(B^{s1},B^{t1}) 
   --                ( h, k ) |--->  ( N*h, h*M - Nsyz*k )
   --
   -- We will ultimately return the quotient ker(\delta) / im(\rho)

   L3 := identityMap(M.target,B); -- identity on B^s0
   L4 := identityMap(N.source,B); -- identity on B^t1
   K3 := N ** (transpose L3);
   K4 := L4 ** (transpose M);
   K5 := Nsyz ** (transpose L2);
   myZeroMap := zeroMap(K3.target,K5.source,B); -- this is a zero block of the appropriate size

   -- Computing Hom in degree d
   --
   -- To do this at the vector space level, we replace every entry in the matrices constructed
   -- above with a matrix representing right or left multiplication, as required by the formulas.
   -- Some care must be taken with degree shifts in the source and target. In particular, some
   -- columns will simply vanish for degree reasons. We must keep track of these, at least for K1.
   
   K1ent := entries K1;
   K2ent := entries K2;
   K3ent := entries K3;
   K4ent := entries K4;
   K5ent := entries K5;
   myZeroMapEnt := entries myZeroMap;
   
   -- The following tracks the source degrees of K1 where the conversion returns the empty matrix.
   -- At the end, we'll go back and insert zeros if needed.
   
   sourceBasisSize := apply(#(K1.source),i-> # flatten entries basis(d-(K1.source)#i,B));
   empties := positions(sourceBasisSize, i-> i==0);

   -- Converting all matrices as described above.
   
   K1' := matrix apply(#(K1.target), i -> apply(#(K1.source), j -> 
	rightMultiplicationMap(K1ent#i#j, d - (K1.source)#j, d - (K1.target)#i)));
   K2' := matrix apply(#(K2.target), i -> apply(#(K2.source), j -> 
	leftMultiplicationMap(-K2ent#i#j, d - (K2.source)#j, d - (K2.target)#i)));
   K3' := matrix apply(#(K3.target), i -> apply(#(K3.source), j -> 
	leftMultiplicationMap(K3ent#i#j, d - (K3.source)#j, d - (K3.target)#i)));
   K4' := matrix apply(#(K4.target), i -> apply(#(K4.source), j -> 
	rightMultiplicationMap(K4ent#i#j, d - (K4.source)#j, d - (K4.target)#i)));
   K5' := matrix apply(#(K5.target), i -> apply(#(K5.source), j -> 
	leftMultiplicationMap(-K5ent#i#j, d - (K5.source)#j, d - (K5.target)#i)));
   myZeroMap' := matrix apply(#(myZeroMap.target), i -> apply(#(myZeroMap.source), j -> 
        leftMultiplicationMap(-myZeroMapEnt#i#j, d - (myZeroMap.source)#j, d - (myZeroMap.target)#i)));
   
   -- The following are the matrix representations of the degree d part of \delta and \rho respectively.
      
   K' := K1'|K2';
   H' := matrix {{K3',myZeroMap'},{K4',K5'}};

   -- Compute the subquotient. 
   
   myHom := prune ((ker K') / (image H')); 

   -- Now reformat to output the map f. 
   -- First minimize the generators and trim down so only f is returned. 
   homGens := mingens image(gens image myHom.cache.pruningMap)^(toList(0..(numgens source K1' - 1)));
   
   -- Convert back to NCMatrices (flattened into a vector at this point)
   basisMatr := fold(apply(#(K1.source), i -> basis(d-(K1.source)#i,B)), (a,b) -> a ++ b);
   flattenedMatrs := basisMatr * homGens;
   
   -- Finally, insert zeros where needed.
   toMingleZeros := zeroMap((K1.source)_empties,flattenedMatrs.source,B);
   if flatten entries flattenedMatrs == {} then {}
   else (
      mingledFlatMatrs := ncMatrix functionMingle(entries flattenedMatrs,entries toMingleZeros,i->sourceBasisSize#i!=0); 
      retVal := apply(apply(#(mingledFlatMatrs.source), i -> flatten entries mingledFlatMatrs_{i}), L -> ncMatrix pack(#(M.target),L));
      retVal
   )
)

TEST ///
restart
needsPackage "NCAlgebraV2"
needsPackage "NCAlgebra"
B = threeDimSklyanin(QQ,{1,1,-1},{x,y,z})
M = ncMatrix {{x,y}}
N = ncMatrix {{x^2,y^2}}
subQuotientAsCokernel(M,N)
///

TEST ///
--- a serious 'production' example of a Hom computation
restart
needsPackage "NCAlgebra"
needsPackage "NCAlgebraV2"
A = skewPolynomialRing(QQ,(-1)_QQ,{x,y,z})
B = QQ{p,q,r}
setWeights(B,{1,3,5})
f = ncMap(A,B,{x+y+z,x^3+y^3+z^3,x^5+y^5+z^5})
relList = {p^2*q - q*p^2, p*q^2-q^2*p, 2*q^2-r*p-p*r,
          4*p^8-12*p*q*p^4+3*p*q*p*q-12*q*p^5+3*q*p*q*p+38*q^2*p^2-12*q*r-12*r*q,
	  12*r^2-5*q*p*q^2-5*p*q^3-10*p^4*q^2+5*p^6*q*p+5*p^7*q-2*p^10}
C = B/(ncIdeal relList)
M = ncMatrix {{p,q,0},{0,q,r}}
assignDegrees(M,{0,0},{1,3,5})
N = ncMatrix {{p,q^5},{p,r^3}}
assignDegrees(N,{0,0},{1,15})
Hom(0,M,M)
///

TEST ///
restart
///


-------------------------------------------
--- Anick Resolution Methods --------------
-------------------------------------------
debug needsPackage "Graphs"

edgesAnick = method();
edgesAnick NCGroebnerBasis := G -> (
    obstructions := (keys G.generators) / first ;
    prevert1 := (gens (first gens G).ring) / (i -> (first keys i.terms).monList);
    premons := apply (keys G.generators / first, m -> m.monList);
    suffixes := select( 
    apply (premons, m -> elements set subsets drop(m,1)) // flatten // set // elements,
    i -> i != {}
    );
    select(suffixes, i -> i != {});
    prevert2 := suffixes;
    vertset := unique (prevert1 | prevert2);
    findSuffix := (t,O) -> (
    	select (O, o -> if #(o.monList) > #t then false else
	    t_(toList(0..(#o.monList-1)) / (i -> i + #t -(#o.monList))) == o.monList
	    )
     );
    childrens := (t,V,O) -> select(V, v -> #(findSuffix(t|v,O)) == 1);
    edgeset :=  {{promote(1, (first gens G).ring),prevert1}} | apply(vertset, v -> {v,childrens(v,vertset,obstructions)})
)

nChains = method();
nChains(ZZ,Digraph) := (n,G) -> ( 
    R := (first (G.vertexSet)).ring;
    P := findPaths(G, first(G.vertexSet),n);
    apply(P,l -> fold(apply (drop(l,1), k -> toString ncMonomial (k, R)),concatenate))
)

needsPackage "Graphs"

digraph NCGroebnerBasis := G -> (
    digraph(edgesAnick(G),EntryMode => "neighbors")   
)

TEST ///
restart
needsPackage "NCAlgebraV2"
needsPackage "NCAlgebra"
needsPackage "Graphs"
A = QQ{x,y}
I = ncIdeal(x^2 - y^2)
G = twoSidedNCGroebnerBasisBergman(I)
E = edgesAnick(G)

--- vvv - depends on a working Graphs2 - vvv ---
D = digraph(E,EntryMode => "neighbors")
first (D.vertexSet)
vertexSet D

--- all paths of length 4 ---
findPaths(D,first (D.vertexSet),4)
--- verify... ---
nChains(4,D)
--------------
--- code to build init file for anick resolution
--- code to build .bi file for anick

///


end

restart
needsPackage "NCAlgebraV2"
needsPackage "NCAlgebra"
A = skewPolynomialRing(QQ,(-1)_QQ,{x,y,z})
setWeights(A,{2,4,6})
basis(5,A)
leftMultiplicationMap(x,5)
setWeights(A,{3,4,6})
leftMultiplicationMap(x,5)
basis(8,A)*leftMultiplicationMap(x,5)

--- bug fix/performance/interface improvements
------------------------------------
--- Testing!

--- additions in the near future
------------------------------------
--- skewPolynomialRing with NCRing bases
--- Finish right mingens
--- Implement left kernels and mingens etc (opposite ring now done)
--- Make sure that trivial ideals are handled correctly
--- Make sure constructions over the tensor algebra are handled correctly
--- isFiniteDimensional?
--- 'basis' for f.d. algebras?
--- Generating set for algebras not over a field
--- fix coefficients to return a pair again.

--- other things to add or work on in due time
-----------------------------------
--- notation to refer to a certain graded piece of an algebra e.g. A_3
--- a dimension function for graded pieces dim(A,17)
--- Dare I say it, Diamond Lemma?
--- Make Quotients of Quotients work.
--- NCRingMap kernels (to a certain degree)  -- Not sure I can do this with
---   Bergman, can't use block orders in bergman.
--- anick resolution
--- NCModules (?) (including module gb (via simple), hilbert series, modulebettinumbers)
--- Work on reduction code a bit?
--- Hilbert series for modules (and sided ideals)
--- enveloping algebras, tensor products of algebra, Hochschild (co)homology?

--- symbols in hash tables of exported types
----
restart
uninstallPackage "NCAlgebraV2"
installPackage "NCAlgebraV2"
needsPackage "NCAlgebraV2"
viewHelp "NCAlgebraV2"

restart
uninstallPackage "NCAlgebra"
installPackage "NCAlgebra"
needsPackage "NCAlgebra"
viewHelp "NCAlgebra"

