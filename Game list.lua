return(function(...)local o,e,E=table,string,bit local t,a,d,r,c,G,F,I,C,i,n=e.byte,e.char,e.sub,o.concat,o.insert,math.ldexp,getfenv and getfenv()or _ENV,setmetatable,select,unpack or o.unpack,tonumber;local s=(function(h)local e,c,l,n,f,t,i=1,function(l)local e=""for n=1,#l,1 do e=e..a(t(l,n)-(-6))end return n(e,36)end,"","",{},256,{}for e=0,t-1 do i[e]=a(e)end;local function s()local l=c(d(h,e,e))e=e+1;local n=c(d(h,e,e+l-1))e=e+l;return n end;l=a(s())f[1]=l;while e<#h do local e=s()if i[e]then n=i[e]else n=l..d(l,1,1)end;i[t]=l..d(n,1,1)f[#f+1],l,t=n,n,t+1 end;return o.concat(f)end)(",/;,1.,1.,/<,1/,.K,1/,/<,/1,1/,/G,01,0.,/O,0-,/<,/.,1/,/J,/G,/I,/T,/M,0+,/<,/3,1/,0.,/T,/G,/<,/0,1O,/D,/G,1C,1T,1.,0/,/S,01,/I,1M,1F,/H,0.,1D,1/,0/,/N,/M,0/,01,1R,1E,1.,1J,/J,0-,/I,1R,2.,/;,/P,2E,/S,1<,1/,/O,0,,0-,/C,/K,/<,//,1/,0+,0-,/G,0*,0-,/M,/E,1S,1/,03,0T,0I,0A,/<,.S,1F,33,/P,33,2E,1@,1B,2?,1.,2J,1B,0/,2F,1/,/H,/M,/K,01,0/,/R,/<,/,,1>,2B,/H,/P,0.,2K,/<,-=,11,/;,./,0Q,./,1*,.,,-T,.+,;H,-S,.,,.*,;G,.*,.-,;M,0T,.,,.+,-E,.,,-S,0R,.,,.,,-Q,./,1-,</,<3,-T,;L,.-,<+,.,,0I,</,<B,.,,0M,</,0N,.,,./,-T,<I,<H,./,<H,.,,0K,.,,.-,.*,</,0J,<I,<Q,.-,-J,<R,-H,<C,<R,<@,0L,<R,<K,.,,=<,.,,<H,.-,-Q,</,=-,<>,1+,<R,0S,=2,=C,<0,;J,./,<Q,-Q,;Q,.-,<3,<N,</,./,<I,</,.,,0O,<I,;Q,.,,..,<0,=1,-Q,-F,<0,<<,0P,<R,=D,.-,-G,<G,<L,=3,>C,<R,<T,.-,-R,<0,>B,=S,>K,=0,=I,>H,./,0G,>J,.-,<K,.-,=1,<P,;H,?,,=O,<R,;G,=?,>R,<=,<I,-E,./,0H,;T,?E,./,0O,./,=+,.,,-G,<2,<I,=<,-T,<<,=H,-T,;S,-T,<.,-T,>B,-T,<H,-T,?P,=+,-T,?E,-T,0F,<0,>;,=D,<0,<T,-Q,;L,-Q,=D,-Q,=/,>*,=Q,<R,=H,.-,>?,?0,>J,.,,?E,-Q,>B,-J,>;,=/,.,,-J,<T,=A,<I,>B,-R,=P,0Q,<0,>0,-Q,<F,-Q,=P,<B,@J,?,,-Q,0E,>H,.,,1,,>S,A1,.-,<>,<+,-R,;L,-R,<1,@*,-S,;F,./,<.,-J,0J,B,,0S,B,,AH,B/,?N,-J,@>,-G,A,,B0,1+,;F,;H,<T,-J,B;,0C,A.,AH,;I,?L,;Q,-G,-H,;F,/2,1/,1/,,0,-F,3@,1.,0.,/C,/N,/I,BR,BS,/;,-T,1,,/;,/+,1/,1=,1.,C2,BS,C*,;B,CB,C3,/;,/K,1,,CC,C3,3O,/;,2A,2C,2E,/<,CC,2N,CF,/;,CL,1.,C*,D-,/;,.G,-C,D0,1*,1,,D+,.L,1/,.M,0@,/;,11,CF,.M,CG,D0,1N,BS,DF,/;,1T,CT,CG,.R,DC,1.,+H,/;,1E,D+,+C,/;,30,CH,/;,;2,D+,1.,/-,E/,/;,/*,/;,CA,BS,;2,E>,BR,.?,1.,;2,;2,DI,1.,30,BR,CL,11,1E,30,/0,/@,D,,E?,DQ,/;,.@,ES,CL,00,/;,1N,DE,1.,1T,2N,1/,BR,F<,CG,E<,F*,FB,D0,C*,C3,.G,BS,0T,FA,DQ,E2,F-,CH,1N,EI,1/,1T,FP,10,DL,FJ,EM,F0,1/,EE,FK,FB,DQ,FS,G1,BS,BR,FL,1N,D0,FR,CH,1=,G3,1=,E@,G/,GE,G1,BR,E@,1;,F=,G<,G-,C3,EL,CH,BR,G3,11,D0,FT,1.,0Q,D@,0H,G0,1.,/.,-O,ES,FT,DI,0A,E<,H?,H,,1.,HA,H<,/;,.M,-L,G-,CC,DK,DM,GB,C3,DK,1E,G3,E.,D@,EF,G*,1.,G/,E;,E*,HF,1.,E>,CF,2.,;2,.N,F*,F,,3G,C3,DS,.T,C>,BS,0D,/;,3G,GQ,/;,.O,E-,IC,3G,EQ,E0,/;,.Q,DQ,H3,IO,DD,I*,.C,GM,1/,HD,FP,J,,E/,J1,G1,/B,/;,E;,E/,E>,;2,C3,I1,CH,J>,HE,G-,JE,IJ,ET,11,DI,+0,J=,C3,/.,+=,DQ,C=,11,E;,/0,++,1/,JS,DR,JN,JA,1.,0E,JN,H*,1.,.P,E=,IK,I-,1N,E>,.3,G0,K+,1/,KD,11,KF,1.,.1,F*,K>,1T,30,K*,K,,1.,-S,F*,DS,E>,FP,-P,IC,G3,3G,EI,DK,IB,F2,IP,G;,IC,IQ,CL,1T,E>,C?,/;,L+,GO,1.,L.,C?,L0,I*,I/,/;,L;,HS,L=,FL,C?,L@,BS,E>,LC,1.,.>,IK,1E,E>,1/,E>,GF,I0,K?,D+,C?,F?,IF,LL,G/,1E,I.,1/,1N,I?,BS,1=,M,,F<,.A,I=,JN,2N,.?,KT,E;,E;,GK,M3,JD,K?,C3,JE,E/,CF,EI,FD,-F,H+,JF,K-,CL,KD,1.,.M,H0,G=,H/,HI,1/,.Q,/J,ES,D?,I2,KR,/;,NK,IP,.=,ES,30,J*,KJ,IK,KI,NM,NO,.?,0;,LL,1N,O/,JJ,G-,/.,.-,G*,3G,11,1=,O*,O@,DL,NM,LO,/;,/S,G-,G?,1.,/?,DT,FQ,/;,.?,02,ON,HP,BS,NS,ET,G/,30,30,O2,DG,LG,DQ,HR,JO,OO,GM,EN,KL,1.,FG,NT,NM,PB,OE,1/,.H,L*,GL,1.,NH,ES,.<,FB,O*,PN,11,O3,2N,1N,.Q,NQ,BR,.B,DQ,F;,NM,Q.,O,,G.,F*,OI,FO,H<,OM,E@,1T,.?,0/,ET,GC,OP,I<,GQ,DI,DS,1.,QA,NM,PH,;B,.D,NF,1/,+?,PJ,LG,N3,H+,CK,E<,FP,QQ,H2,+.,ES,DP,NL,1/,R<,OP,0-,G-,J*,.O,GA,GS,BS,EI,P0,G*,ND,GG,H1,F3,G*,1=,G/,F;,DQ,JI,HL,F<,Q>,QB,RN,F1,BS,GA,F<,HL,RN,1/,J,,PR,RA,S/,11,.O,/K,NF,DI,OI,GA,DI,/E,LL,1T,/.,/L,G-,.I,Q/,PF,1.,SO,Q3,1.,.E,DQ,NB,G*,CF,/.,R3,1T,T+,R=,T*,Q/,NM,.F,T,,H0,GA,1/,QQ,S3,1.,QT,HB,E@,D0,/,,R.,C3,.O,TL,BS,/K,1-,FD,TO,1/,CJ,C3,PN,1/,+K,FJ,J*,GP,N=,QR,OP,1.,Q>,G>,P2,TB,MI,E<,1E,M@,SK,JF,QF,P<,FL,EP,HM,EK,BS,OT,C3-+*M,C3,;2,M@,1E,;2,CL,P/,CH,EH,N,,M@,KP,JF,1N,P;,CG,2G,BS,OA,E<-+*E,HE,RQ,RJ,S0-++C,S.,G-,RL,F>-++F,1T,RP,QL,DQ,GK,RR-++Q,LL,OO,N<,CF,CF,N3,C3,IB,1/,+F-+*0,L>,IH,RG,P2-++H,CM-++E,GM,M@,P1,GL,EI,G/,J*,D+,JK,E<-+,+,J--+*3,/;,TT,1.-+*+,BS,.J,BS,T?,FA-+*1,GN,DH-++G,OJ,L>,S/,GM,G3,G3,RN,M@-++K,CL,Q>,C3,1T,FL,OB,FN,ET,G,-+-=-+*3-+,<,G/,GQ,D+-+-L,CG,K<,GM,D0-+,<-+,@,1.,LD-+*3,D/,CH,-O-+,P,/;,,0,TR,CH,-P-+.2,-F-+.2,1,-+.2,,0++,N<,D-,+O+R-+,P,+S,+>-+.2,-S,1+,C3,-K,BS,0R,FJ,FT,G,,N0,DQ,BR,DK,ND,C3-+-3-++F,L<,1=,L<,1E-+-/-+/>-+*<-+-1,FP-+-B-+/3,HM-+/=,LL,DK,30,GK,RN-+*Q-++O,FL,ME,LM,30-++>,C@,IK,BR,JI,1=-+/J,/;,.2,RN,QO,IO,O*-+02,O*,NQ,11,.2,/F,G-,S=-+03,NM-+0C,O*,Q2,QG,ON,1=,JA,QQ-+/@,F3,NM,.+,T@,T.,NE,BR,K1,O*-+0Q-+0?,/=,G*-+1-,MO-+0P,DQ-+0@,G-,KH-+0D,KG,T=,1/,.,,DQ,-S,+1,ON,11,JA,-M-+0J,OS,R3,1E-+1C,T;,/;-+1O,SQ,/;,.*-+1D-+1F-++*,IO,/;-+1J,1E,1=,2G-+0M,JF,F,-+0N,1.-+0Q-+0.,I+,HT,LB-+*N,IO,ED,EJ,G--+.--+0*,IK,1/,MD-+2L,H2-+,N,PO-+,M-+.+,F@,CD,N;,CH,C<,D+,O>,H2,EI,JC,ST,M=,1.,F,,D0,K3,ND,C2,QK,HE-+1<,HT,PC,1/,E1-+1S,JC,T--+.*,QQ-+.*-+3>,G1,/Q-+*;,OO,GD-+,>,QE,Q;-+;,,FP,GJ,JF-+-R,GN,G3-+.*,CG-+;;,HN-+*=-+;+-+-D,LP-+*H,I*,1N,.0,MN-+*K,1/,0>,IO-+/K,JN-+/S,M<,LR,L>,3G-+;O,LN,ON,JB-+<*,N.,GM,DK,E>,M@,EB,CH,HR,CL,BR,EO,DL,ER,1N,T3-+3=,G-,P;,DS,TE-+*<,1N,F<,/R-+;+,TG,FB-+,,,CF,M.,BS,N/-+<C,C3,03-+*3,IQ-+,,-+<D,D-,.M,PN-+/2,P=,GR,E<,FL-++?,1/-+<<,CH-+./-+*R-+.2-+3*,BS-+.2,TN,D0,.G-+.C,C=,BS,NM,/;,MM-+-,-+,K,R/-++T,S;-+/F,CH-+2N-+*P-+*3-++;,MN,M@,-E-+0S,CL-+/K,HO,L>-+;I,LM-+3I,S;,1E,..,MN,JC,GL,JC,C?,.2-+1/,E>-+0C,F>-+0E,MN,OD,1/,K3,OD,BR-+1<,3G-+02-+<J,QN-+1A,T<,;B-+>G-+2J,1.,0P,IC-+1P-+;G-+1.,K?-+0>,G--+0=-+>S,JF-+?+-+/-,K/,C?,MH,O*-+?C-+0/-+0A,E>,PQ-+?3,/;-+@*-+?P-+?I,FP-+?K-+-R,DS-+?N,BS,IJ,1=,E;,M?,ER,1E,IJ,11,T--+/P,F+-+2O-+?*,O+,ES,T--+>D,DL,0I,ON,QT,;B,F,-+>I,1.,0O-+3<,CL,M?,CH,3G,M1,LM,OG,LM-+=.,CH,LS,ES-+00,IC,HH-+,J,O*-+AB-+1S,+B,MN-+A.,1/-+,T-+A0,LP,IB,2N,DK,LT,C3-+A>,CL,IM,CH,IB-+A1-+AP,ET,NA,1.,DP-+;T,3G,DP,CL-+AN,CH,IQ-+;M-+A<,CL,DP-+;M,R?,CL,IJ,K>-+,/,/;,K>-+?D,C?,0F,G2-+1S-+BO-+@R,L=,GK,0=,LQ,ES,JI,IB,BR,IQ,NG-+B/,BS-+BB,II,1.,IB,1=,IQ,F<-+3R-+BM,/;,DB-+3G,1.-+CF-+<D-+C1,BS,K3-+C<,.O,.;-+<*-+C0-+1S-+CC-+?R,IC,O0,KI-+1S-+D,-+1S,01,MN-+CK-+@I-+C<,.?,RA,IQ,IQ,30-+CO-+CQ,L=,O*-+CT-+>M,IC-+CT-+>Q,1/-+CT-+@G-+D3,1.,/H-+C,-+2G,L=-+D@-+C=-+DC-+D3-+B@-+B?-+?L-+C.,ET-+C1,F,-+CA,M*,/;,DP,MH,DK-+@C,LP-+BL-+E.,K>-+?-,PK,/;,/G,KE,NM-+EI,PR-+EI,IQ-+B>-+BK-+BT,L=-+DB-+B>-+E2-+DD,BS,+I-+E=,MA-+B0-+C=-+AO,K=-+>+,L=-+EE-+0/-+EG,OM-+CG,/;-+FA-+1S,/>,DQ,.?-+EN-+DC-+EQ-+E-,IQ-+ET,ES-+F+-+E;,1/-+F.-+E>,LP,IJ,HJ-+F;,D0,IQ-+F>-+A@,IQ-+,2-+FB-+G3-+1S,+A-+FG-+FI-+C?-+F;-+FL,II-+CP-+GA-+C1,JI,JN-+AN-+@A,/;-+11-+@E,G1,F,-++<,/;,K3,P+-+/.,H0-+@M,/0-+@O,1E,R3,S>,K?,E;-+BS,C?-+/S,K3,C?-+-R-+EA,MK-+GK,+<,MN-+@F,K3,I.-+0+-+CP,OK-+23-+3S-+<N,N1-+2S,D.-+3,,CH-+.2,TK,/3,CF-+A1,R,-+=C++,/<-+<Q-+.F-++.-+=F-+.2,.K-+=I-+.2-+=L,D0,.C-+=N,1>,BS,+@,L>-+-Q-+-G,G@,LG,DK-+/<,LP-+2>-+=A,E<,K1-+<.,E/,K1-+BS,K*,D@,-N,K?,G3-+?>,1/,JE-+DR,MS,G1-+A1-+AR-+;?,MA,M@,IB,JE-+B.,I2,1.,3G,EE,EN,KD,1N-+0C,DP,O*-+0C-+FC-+C=,DP,O2,BR,K>,R?-+EQ,K>,;2-+BI,IJ-+DA-+EQ-+0G-+FG-+0+-+F/,;B,K>,IJ,;2,JI,IJ,C?,DP,IJ,IN,3G,NO-+JR,3G,E;-+K*,MA-+>T,0*-+<*-+D3,K>,LO,RP-+G@-+1;,+/,L=-+AE,OB,NM-+AE,.2-+L/,IQ,-T-+EJ,1/-+L?-+?D,IQ-+11,Q0,1/-+11-+FH-+F/,IB,2G-+K,,IC,DP,/;,QQ-+B<,FQ,NM,SM,;B-+HN-+LS,1/-+M*,IP,NI,1E,L.,11-+CA,NM-+M3,TF,R*,O*-+M/-+LI,DP-+LK-+F;,DP-+KF,1.-+LQ,HE-+MA-+1;,FG,IQ,-G,P3-+1S-+MP-+3;-+?@-+0?-+0A,IQ,-F,DQ-+*S,NM-+N.-+3;,FI-+EM-+LJ-+<+,DP-+MG-+F/,G/,IJ-+GA,G/-+L*-+2.-+B1-+C=,KN,BS-+MB-+EI-+MD-+<+,T+-+GH,1/-+KE-+F/-+KH-+LT-+MM,L=,0K,DQ,KQ,1/-+O.-+3;,K3-+N<-+NN,2G-+N?-+LN-+/A-+NC,P,-+F;,IB-+IS-+KG-+K;-+NK,DQ,PL,E>,0?-+OJ-+1S-+OM-+O<-+<*,2G-+NP,CH-+NS-+OG-+ML-+OQ-+ME,/;,+G-+E*-+A=-+NT-+/A,GH,D+-+L+-+/A-+O=,BS-+N@,DP-+NB-+<*-++N-+EQ-+OE-+PB-+NI-+P<,O;,1/-+P?,G/-+PA,R>-+O@-+PE-+ND-+OD-+NG-+P;,K>,RL-+IN-+PN-++P-+P@-+OR-+PJ-+MH-+PR,CC-+Q/,G1-+P?-+2T,.?-+;0-+IN,O*,M.-+M+,R*-+.--+LI,EI-+N<,2N,ED-+EI,E@,1N,IS-++>-++@,/;,J3,J0-+=<-+R,-+/T,J.,H@,R*-+LP,ON,CL-+M,,1.-+KR,NA,13-+---+//,HE,DK-+/D-++D-++K-++J-+OC-+R=,ON,P--+MQ,G/-+3I,;2,DK-+J=-+2B,JN,E;,E>-+<0,IC-+2P,K?-+A<-+3;-+A<,O*,DF-+@D+T,K?-+2J,K3,JC-+<>,KB,/;,I<-+FB-+SH,HF-+S@,E>-+E?-+S@,C?-+,0-+SK,MA-+CK,.M-+S@,IB-+LO,DT,R3,IB-+02-+0O,PG-+@+-+<C-+LI,LO,DP-+T*-+ES-+2M,H;-+T--+R+,J3,GK,J3,F<,J3-+D3,J3-+/S,J3,DE,H0-+BH,ID-+F

