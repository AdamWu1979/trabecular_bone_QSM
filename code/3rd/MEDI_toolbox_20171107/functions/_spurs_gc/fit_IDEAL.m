function [water fat freq iter model]= fit_IDEAL(s0, t, f_fat, f0, R2s, max_iter)
matrix_size = size(s0);
numvox = prod(matrix_size(1:end-1));
numte = matrix_size(end);


if nargin<6
    max_iter = 30;
end
if (nargin <5) || (isempty(R2s))
    R2s = zeros([1 numvox]);
end
if nargin<4;
    f0 = zeros([1 numvox]);
end
if nargin<3;
    f_fat = -420;
end

s0 = permute(s0, [length(matrix_size) 1:length(matrix_size)-1]);
s0 = reshape(s0,[numte numvox]);
R2s = reshape(R2s,[1 numvox]);
f0 = reshape(f0,[1 numvox]);
t = reshape(t,[numte 1]);
t = repmat(t,[1 numvox]);

o = ones([numte numvox]).*exp(repmat(-R2s,[numte 1]).*t);
z = zeros([numte numvox]).*exp(repmat(-R2s, [numte 1]).*t);
c = real(exp(1i*2*pi*f_fat*t)).*exp(repmat(-R2s, [numte 1]).*t);
d = imag(exp(1i*2*pi*f_fat*t)).*exp(repmat(-R2s, [numte 1]).*t);

% A = [ones(size(t)) exp(1i*2*pi*f_fat*t)];
% A = [ [o;z]  [z;o] [c; d] [-d;c] ];
Acol01 = cat(1, o, z);
Acol02 = cat(1, z, o);
Acol03 = cat(1, c, d);
Acol04 = cat(1, -d, c);


y = zeros([5 numvox]);
dy = zeros([5 numvox]);
dy(1,:) = 1e4;
iter = 0;

y(1,:) = f0;
s = s0./exp(1i*2*pi*repmat(y(1,:),[numte 1]).*t);
y(2:5,:) = invA(Acol01, Acol02, Acol03, Acol04, cat(1, real(s), imag(s)));

update = dy(1,:);
while (iter<max_iter)&&(sqrt(sum(update.^2,2)/numvox)>0.1)
    sr = real(s) - (repmat(y(2,:),[numte 1]).*o - repmat(y(3,:),[numte 1]).*z + repmat(y(4,:),[numte 1]).*c - repmat(y(5,:),[numte 1]).*d);
    si = imag(s) - (repmat(y(2,:),[numte 1]).*z + repmat(y(3,:),[numte 1]).*o + repmat(y(4,:),[numte 1]).*d + repmat(y(5,:),[numte 1]).*c);

    gr = 2*pi*t.*(-repmat(y(2,:),[numte 1]).*z - repmat(y(3,:),[numte 1]).*o - repmat(y(4,:),[numte 1]).*d - repmat(y(5,:),[numte 1]).*c);
    gi = 2*pi*t.*(repmat(y(2,:),[numte 1]).*o - repmat(y(3,:),[numte 1]).*z + repmat(y(4,:),[numte 1]).*c - repmat(y(5,:),[numte 1]).*d);
%     B = [[gr; gi] A];
%     dy =B\[sr;si];
    Bcol01 = cat(1, gr, gi);
    dy = invB(Bcol01, Acol01, Acol02, Acol03, Acol04, cat(1, sr,si));    
    y = y+dy;
    iter = iter+1;
    s = s0./exp(1i*2*pi*repmat(y(1,:),[numte 1]).*t);
    y(2:5,:) = invA(Acol01, Acol02, Acol03, Acol04, cat(1, real(s), imag(s)));
   

    update = dy(1,:);
    update(isnan(update)) = 0;
    update(isinf(update)) = 0;
    
end

freq = reshape(y(1,:),matrix_size(1:end-1));
water = reshape(y(2,:),matrix_size(1:end-1)) + 1i*reshape(y(3,:),matrix_size(1:end-1));
fat = reshape(y(4,:),matrix_size(1:end-1)) + 1i*reshape(y(5,:),matrix_size(1:end-1));
model = Acol01.*repmat(y(2,:),[2*numte 1]) + Acol02.*repmat(y(3,:),[2*numte 1]) + Acol03.*repmat(y(4,:),[2*numte 1]) + Acol04.*repmat(y(5,:),[2*numte 1]);
model = model(1:end/2,:)+1i*model(end/2+1:end,:);
model = model.*exp(1i*2*pi*repmat(y(1,:),[numte 1]).*t);
model = permute(model, [2 1]);
model = reshape(model,matrix_size);
% s_model = [s0;model];
% figure; plot(s0,'ro'); hold on; plot(model,'bx');hold off;
% axis([-max(abs(real(s_model))) max(abs(real(s_model))) -max(abs(imag(s_model))) max(abs(imag(s_model)))]*1.2)

freq(isinf(freq)) = 0;
freq(isnan(freq)) = 0;
water(isinf(water)) = 0;
water(isnan(water)) = 0;
fat(isinf(fat)) = 0;
fat(isnan(fat)) = 0;
model(isinf(model)) = 0;
model(isnan(model)) = 0;


function x=invA(col1, col2, col3, col4, y)
% assemble A'*A
a11 = sum(col1.*col1,1);
a12 = sum(col1.*col2,1);
a13 = sum(col1.*col3,1);
a14 = sum(col1.*col4,1);
a22 = sum(col2.*col2,1);
a23 = sum(col2.*col3,1);
a24 = sum(col2.*col4,1);
a33 = sum(col3.*col3,1);
a34 = sum(col3.*col4,1);
a44 = sum(col4.*col4,1);

% inversion of A'*A
d = (a33.*a44.*a12.^2 - a12.^2.*a34.^2 - 2.*a44.*a12.*a13.*a23 + 2.*a12.*a13.*a24.*a34 + 2.*a12.*a14.*a23.*a34 - 2.*a33.*a12.*a14.*a24 - a13.^2.*a24.^2 + a22.*a44.*a13.^2 + 2.*a13.*a14.*a23.*a24 - 2.*a22.*a13.*a14.*a34 - a14.^2.*a23.^2 + a22.*a33.*a14.^2 + a11.*a44.*a23.^2 - 2.*a11.*a23.*a24.*a34 + a11.*a33.*a24.^2 + a11.*a22.*a34.^2 - a11.*a22.*a33.*a44);
ia11 = (a44.*a23.^2 - 2.*a23.*a24.*a34 + a33.*a24.^2 + a22.*a34.^2 - a22.*a33.*a44)./d;
ia12 = -(a12.*a34.^2 - a13.*a24.*a34 - a14.*a23.*a34 + a14.*a24.*a33 + a13.*a23.*a44 - a12.*a33.*a44)./d;
ia13 = -(a13.*a24.^2 - a14.*a23.*a24 - a12.*a24.*a34 + a14.*a22.*a34 + a12.*a23.*a44 - a13.*a22.*a44)./d;
ia14 = -(a14.*a23.^2 - a13.*a23.*a24 - a12.*a23.*a34 + a12.*a24.*a33 + a13.*a22.*a34 - a14.*a22.*a33)./d;
ia22 = (a44.*a13.^2 - 2.*a13.*a14.*a34 + a33.*a14.^2 + a11.*a34.^2 - a11.*a33.*a44)./d;
ia23 = -(a14.^2.*a23 - a13.*a14.*a24 - a12.*a14.*a34 + a11.*a24.*a34 + a12.*a13.*a44 - a11.*a23.*a44)./d;
ia24 = -(a13.^2.*a24 - a13.*a14.*a23 - a12.*a13.*a34 + a12.*a14.*a33 + a11.*a23.*a34 - a11.*a24.*a33)./d;
ia33 = (a44.*a12.^2 - 2.*a12.*a14.*a24 + a22.*a14.^2 + a11.*a24.^2 - a11.*a22.*a44)./d;
ia34 = -(a12.^2.*a34 - a12.*a13.*a24 - a12.*a14.*a23 + a13.*a14.*a22 + a11.*a23.*a24 - a11.*a22.*a34)./d;
ia44 = (a33.*a12.^2 - 2.*a12.*a13.*a23 + a22.*a13.^2 + a11.*a23.^2 - a11.*a22.*a33)./d;
% y project onto A'
py1 = sum(col1.*y,1);
py2 = sum(col2.*y,1);
py3 = sum(col3.*y,1);
py4 = sum(col4.*y,1);
% calculate x
x(1,:) = sum(ia11.*py1 + ia12.*py2 + ia13.*py3 + ia14.*py4,1);
x(2,:) = sum(ia12.*py1 + ia22.*py2 + ia23.*py3 + ia24.*py4,1);
x(3,:) = sum(ia13.*py1 + ia23.*py2 + ia33.*py3 + ia34.*py4,1);
x(4,:) = sum(ia14.*py1 + ia24.*py2 + ia34.*py3 + ia44.*py4,1);

function x=invB(col1, col2, col3, col4, col5,y)
% assemble B'*B
b11 = sum(col1.*col1,1);
b12 = sum(col1.*col2,1);
b13 = sum(col1.*col3,1);
b14 = sum(col1.*col4,1);
b15 = sum(col1.*col5,1);
b22 = sum(col2.*col2,1);
b23 = sum(col2.*col3,1);
b24 = sum(col2.*col4,1);
b25 = sum(col2.*col5,1);
b33 = sum(col3.*col3,1);
b34 = sum(col3.*col4,1);
b35 = sum(col3.*col5,1);
b44 = sum(col4.*col4,1);
b45 = sum(col4.*col5,1);
b55 = sum(col5.*col5,1);

% inversion of B'*B
d = (-b23.*b45.*b12.*b13.*b45-b11.*b23.*b45.*b34.*b25+b23.*b35.*b12.*b14.*b45+b23.*b45.*b14.*b13.*b25-b23.*b11.*b45.*b24.*b35+b11.*b23.*b44.*b35.*b25-b23.*b34.*b12.*b14.*b55+b23.*b44.*b12.*b13.*b55-b23.*b14.*b13.*b24.*b55+b23.*b15.*b14.*b34.*b25+b23.*b15.*b13.*b24.*b45-b23.*b44.*b35.*b12.*b15-b23.*b34.*b24.*b15.*b15+b23.*b45.*b34.*b12.*b15+b23.*b35.*b24.*b14.*b15-b23.*b44.*b15.*b13.*b25-b23.*b14.*b14.*b35.*b25-b11.*b23.*b35.*b24.*b45-b45.*b22.*b34.*b13.*b15-b45.*b33.*b14.*b12.*b25+b35.*b24.*b13.*b12.*b45-b35.*b24.*b14.*b12.*b35-b22.*b35.*b34.*b14.*b15+b22.*b33.*b45.*b14.*b15+b45.*b34.*b13.*b12.*b25-b45.*b33.*b24.*b12.*b15-b45.*b22.*b14.*b13.*b35+b45.*b22.*b13.*b13.*b45-b33.*b25.*b24.*b14.*b15-b22.*b33.*b44.*b15.*b15+b33.*b24.*b24.*b15.*b15+b45.*b33.*b12.*b12.*b45-b35.*b24.*b24.*b13.*b15+b45.*b24.*b12.*b13.*b35-b45.*b34.*b12.*b12.*b35+b34.*b24.*b15.*b12.*b35-b44.*b35.*b13.*b12.*b25-b44.*b25.*b12.*b13.*b35+b44.*b33.*b25.*b12.*b15-b45.*b13.*b13.*b24.*b25+b22.*b34.*b34.*b15.*b15+b34.*b24.*b25.*b13.*b15-b34.*b24.*b13.*b12.*b55+b44.*b35.*b12.*b12.*b35+b44.*b22.*b15.*b13.*b35+b34.*b12.*b12.*b34.*b55+b22.*b34.*b13.*b14.*b55+b22.*b14.*b13.*b34.*b55+b33.*b14.*b12.*b24.*b55+b44.*b13.*b13.*b25.*b25-b44.*b33.*b12.*b12.*b55+b24.*b34.*b15.*b13.*b25-b24.*b34.*b12.*b13.*b55+b24.*b34.*b35.*b12.*b15+b44.*b22.*b35.*b13.*b15+b14.*b12.*b34.*b35.*b25+b33.*b24.*b12.*b14.*b55-b25.*b34.*b14.*b13.*b25+b25.*b34.*b12.*b13.*b45-b15.*b14.*b22.*b34.*b35-b15.*b14.*b33.*b24.*b25-b33.*b25.*b12.*b14.*b45+b14.*b14.*b22.*b35.*b35+b14.*b14.*b33.*b25.*b25+b44.*b33.*b15.*b12.*b25-b44.*b22.*b13.*b13.*b55-b22.*b33.*b14.*b14.*b55+b14.*b13.*b24.*b25.*b35-b13.*b13.*b25.*b24.*b45-b25.*b13.*b14.*b34.*b25-b22.*b35.*b13.*b14.*b45-b15.*b12.*b34.*b34.*b25-b35.*b12.*b12.*b34.*b45-b35.*b12.*b14.*b24.*b35-b15.*b13.*b24.*b24.*b35-b33.*b15.*b12.*b24.*b45-b25.*b34.*b34.*b12.*b15-b22.*b15.*b13.*b34.*b45+b22.*b33.*b15.*b14.*b45+b13.*b13.*b24.*b24.*b55+b24.*b13.*b14.*b35.*b25+b34.*b12.*b14.*b25.*b35+b11.*b23.*b34.*b24.*b55+b11.*b22.*b33.*b44.*b55-b11.*b34.*b24.*b25.*b35+b11.*b45.*b33.*b24.*b25+b11.*b25.*b34.*b34.*b25+b11.*b45.*b22.*b34.*b35+b11.*b33.*b25.*b24.*b45-b11.*b44.*b22.*b35.*b35-b11.*b33.*b24.*b24.*b55+b11.*b22.*b35.*b34.*b45+b11.*b35.*b24.*b24.*b35-b11.*b22.*b34.*b34.*b55-b11.*b44.*b33.*b25.*b25-b11.*b22.*b33.*b45.*b45-b11.*b24.*b34.*b35.*b25-b23.*b11.*b23.*b44.*b55+b23.*b11.*b23.*b45.*b45+b23.*b11.*b44.*b25.*b35-b23.*b11.*b25.*b34.*b45+b23.*b11.*b24.*b34.*b55+b23.*b23.*b14.*b14.*b55-b23.*b23.*b15.*b14.*b45-b23.*b23.*b45.*b14.*b15+b23.*b23.*b44.*b15.*b15-b23.*b44.*b15.*b12.*b35+b23.*b15.*b12.*b34.*b45-b23.*b14.*b12.*b34.*b55+b23.*b25.*b34.*b14.*b15+b23.*b25.*b13.*b14.*b45+b23.*b15.*b14.*b24.*b35-b23.*b44.*b25.*b13.*b15-b23.*b24.*b13.*b14.*b55-b23.*b14.*b14.*b25.*b35-b23.*b45.*b13.*b12.*b45+b23.*b45.*b14.*b12.*b35+b23.*b44.*b13.*b12.*b55+b23.*b45.*b24.*b13.*b15-b23.*b24.*b34.*b15.*b15);
ib11=(-b23.*b23.*b44.*b55+b23.*b23.*b45.*b45+b23.*b44.*b25.*b35-b23.*b25.*b34.*b45-b23.*b45.*b24.*b35+b23.*b24.*b34.*b55-b23.*b45.*b34.*b25-b23.*b35.*b24.*b45+b23.*b44.*b35.*b25+b23.*b34.*b24.*b55+b22.*b33.*b44.*b55-b34.*b24.*b25.*b35+b45.*b33.*b24.*b25+b25.*b34.*b34.*b25+b45.*b22.*b34.*b35+b33.*b25.*b24.*b45-b44.*b22.*b35.*b35-b33.*b24.*b24.*b55+b22.*b35.*b34.*b45+b35.*b24.*b24.*b35-b22.*b34.*b34.*b55-b44.*b33.*b25.*b25-b22.*b33.*b45.*b45-b24.*b34.*b35.*b25)./d;
ib12=(-b14.*b24.*b35.*b35+b14.*b24.*b55.*b33-b14.*b55.*b23.*b34-b14.*b25.*b45.*b33+b14.*b35.*b25.*b34+b14.*b23.*b45.*b35+b24.*b35.*b45.*b13+b24.*b34.*b15.*b35-b24.*b45.*b15.*b33-b24.*b55.*b34.*b13-b12.*b34.*b45.*b35-b35.*b44.*b13.*b25+b45.*b12.*b45.*b33+b44.*b12.*b35.*b35+b55.*b12.*b34.*b34-b34.*b15.*b25.*b34+b55.*b23.*b44.*b13+b25.*b45.*b34.*b13-b23.*b44.*b15.*b35-b23.*b45.*b45.*b13-b35.*b45.*b34.*b12+b45.*b15.*b23.*b34-b55.*b44.*b12.*b33+b44.*b25.*b15.*b33)./d;
ib13=(-b14.*b23.*b55.*b24+b14.*b23.*b25.*b45+b14.*b35.*b25.*b24-b14.*b25.*b34.*b25-b14.*b22.*b35.*b45+b14.*b22.*b34.*b55+b23.*b45.*b15.*b24+b23.*b55.*b44.*b12-b23.*b44.*b25.*b15-b23.*b45.*b12.*b45+b24.*b13.*b24.*b55-b24.*b45.*b13.*b25-b24.*b35.*b24.*b15-b13.*b25.*b24.*b45+b35.*b24.*b12.*b45-b44.*b22.*b13.*b55+b44.*b22.*b35.*b15+b45.*b22.*b13.*b45-b44.*b35.*b12.*b25+b34.*b24.*b25.*b15+b45.*b34.*b12.*b25+b44.*b13.*b25.*b25-b45.*b22.*b34.*b15-b34.*b24.*b12.*b55)./d;
ib14=-(b14.*b23.*b35.*b25-b14.*b23.*b55.*b23+b14.*b55.*b22.*b33-b14.*b33.*b25.*b25+b14.*b35.*b25.*b23-b14.*b35.*b22.*b35-b23.*b34.*b15.*b25-b23.*b35.*b12.*b45+b23.*b55.*b12.*b34+b23.*b45.*b15.*b23-b45.*b15.*b22.*b33-b55.*b33.*b12.*b24-b55.*b22.*b13.*b34+b34.*b15.*b22.*b35-b35.*b24.*b15.*b23-b45.*b13.*b25.*b23+b55.*b13.*b23.*b24-b35.*b25.*b12.*b34-b35.*b13.*b25.*b24+b34.*b13.*b25.*b25+b35.*b35.*b12.*b24+b33.*b25.*b12.*b45+b35.*b22.*b13.*b45+b33.*b24.*b15.*b25)./d;
ib15=-(b23.*b23.*b14.*b45-b23.*b23.*b44.*b15+b23.*b44.*b12.*b35+b23.*b24.*b34.*b15-b23.*b12.*b34.*b45-b23.*b14.*b24.*b35-b23.*b13.*b24.*b45+b23.*b34.*b24.*b15-b23.*b14.*b34.*b25+b23.*b44.*b13.*b25-b22.*b34.*b34.*b15-b33.*b24.*b24.*b15-b22.*b33.*b14.*b45-b44.*b33.*b12.*b25+b22.*b13.*b34.*b45+b22.*b33.*b44.*b15+b14.*b22.*b34.*b35+b33.*b12.*b24.*b45-b24.*b34.*b13.*b25-b44.*b22.*b13.*b35+b14.*b33.*b24.*b25+b13.*b24.*b24.*b35-b34.*b24.*b12.*b35+b12.*b34.*b34.*b25)./d;
ib22=(-b14.*b13.*b45.*b35+b14.*b13.*b55.*b34+b14.*b45.*b15.*b33+b14.*b14.*b35.*b35-b14.*b55.*b33.*b14-b14.*b15.*b35.*b34-b13.*b45.*b15.*b34+b13.*b44.*b15.*b35+b13.*b45.*b45.*b13-b13.*b55.*b13.*b44-b11.*b44.*b35.*b35-b14.*b35.*b45.*b13-b45.*b11.*b45.*b33+b15.*b35.*b13.*b44+b55.*b14.*b13.*b34-b55.*b11.*b34.*b34+b45.*b15.*b33.*b14+b34.*b15.*b15.*b34-b34.*b14.*b15.*b35+b11.*b34.*b45.*b35-b45.*b34.*b15.*b13-b44.*b15.*b15.*b33+b11.*b45.*b35.*b34+b55.*b11.*b33.*b44)./d;
ib23=-(b14.*b23.*b45.*b15-b14.*b23.*b55.*b14+b14.*b55.*b34.*b12-b14.*b34.*b25.*b15-b14.*b45.*b35.*b12+b14.*b35.*b25.*b14+b23.*b55.*b11.*b44-b23.*b44.*b15.*b15+b23.*b45.*b15.*b14-b23.*b45.*b11.*b45+b45.*b11.*b35.*b24+b34.*b25.*b11.*b45+b44.*b15.*b35.*b12+b44.*b13.*b25.*b15-b55.*b12.*b13.*b44-b35.*b24.*b15.*b14-b45.*b13.*b25.*b14-b55.*b34.*b24.*b11-b45.*b15.*b13.*b24-b45.*b15.*b34.*b12+b34.*b24.*b15.*b15+b13.*b24.*b55.*b14-b35.*b25.*b11.*b44+b45.*b45.*b12.*b13)./d;
ib24=(-b14.*b23.*b13.*b55+b14.*b23.*b15.*b35+b14.*b13.*b35.*b25+b14.*b33.*b12.*b55-b14.*b35.*b12.*b35-b14.*b15.*b33.*b25+b23.*b45.*b13.*b15+b23.*b11.*b34.*b55-b23.*b11.*b45.*b35-b23.*b34.*b15.*b15+b13.*b13.*b24.*b55-b45.*b13.*b13.*b25-b35.*b24.*b13.*b15+b34.*b15.*b13.*b25+b11.*b35.*b24.*b35+b34.*b35.*b12.*b15+b45.*b12.*b13.*b35-b11.*b33.*b24.*b55+b33.*b24.*b15.*b15+b11.*b45.*b33.*b25-b15.*b13.*b24.*b35-b45.*b33.*b12.*b15-b34.*b12.*b13.*b55-b35.*b25.*b11.*b34)./d;
ib25=-(-b23.*b13.*b14.*b45+b23.*b14.*b14.*b35+b13.*b14.*b34.*b25+b33.*b12.*b14.*b45-b14.*b14.*b33.*b25-b34.*b12.*b14.*b35+b23.*b44.*b13.*b15-b23.*b11.*b44.*b35+b23.*b11.*b34.*b45-b23.*b34.*b14.*b15+b13.*b13.*b24.*b45-b34.*b24.*b13.*b15-b44.*b13.*b13.*b25-b11.*b33.*b24.*b45+b33.*b24.*b14.*b15-b34.*b12.*b13.*b45-b44.*b33.*b12.*b15+b44.*b12.*b13.*b35+b11.*b44.*b33.*b25-b14.*b13.*b24.*b35+b34.*b14.*b13.*b25+b11.*b34.*b24.*b35-b11.*b34.*b34.*b25+b34.*b34.*b12.*b15)./d;
ib33=-(b14.*b24.*b25.*b15-b14.*b24.*b55.*b12+b14.*b55.*b22.*b14-b14.*b22.*b45.*b15+b14.*b25.*b45.*b12-b14.*b25.*b14.*b25-b24.*b24.*b15.*b15+b24.*b45.*b15.*b12+b24.*b55.*b11.*b24-b24.*b25.*b11.*b45-b55.*b11.*b22.*b44-b45.*b12.*b45.*b12+b24.*b12.*b45.*b15+b25.*b45.*b14.*b12+b22.*b45.*b11.*b45-b44.*b25.*b15.*b12+b44.*b12.*b55.*b12+b24.*b15.*b14.*b25+b44.*b22.*b15.*b15-b25.*b44.*b15.*b12-b45.*b15.*b22.*b14+b25.*b11.*b44.*b25-b25.*b45.*b11.*b24-b55.*b14.*b12.*b24)./d;
ib34=-(-b14.*b13.*b55.*b22+b14.*b13.*b25.*b25-b14.*b12.*b35.*b25+b14.*b15.*b35.*b22+b14.*b55.*b23.*b12-b14.*b25.*b23.*b15-b13.*b25.*b12.*b45+b13.*b45.*b15.*b22-b13.*b24.*b15.*b25+b13.*b55.*b12.*b24-b11.*b45.*b35.*b22+b12.*b35.*b12.*b45+b55.*b11.*b22.*b34+b25.*b15.*b12.*b34-b55.*b11.*b23.*b24+b25.*b11.*b23.*b45-b45.*b15.*b23.*b12-b55.*b12.*b12.*b34-b34.*b15.*b15.*b22+b34.*b12.*b15.*b25-b15.*b35.*b12.*b24+b24.*b15.*b23.*b15+b11.*b24.*b35.*b25-b11.*b34.*b25.*b25)./d;
ib35=(b24.*b13.*b14.*b25-b12.*b14.*b24.*b35-b22.*b13.*b14.*b45+b23.*b12.*b14.*b45+b14.*b14.*b22.*b35-b23.*b14.*b14.*b25-b24.*b24.*b13.*b15-b11.*b24.*b34.*b25+b24.*b34.*b12.*b15+b11.*b24.*b24.*b35-b44.*b13.*b12.*b25+b24.*b13.*b12.*b45+b44.*b22.*b13.*b15-b23.*b44.*b12.*b15-b11.*b44.*b22.*b35-b22.*b34.*b14.*b15-b24.*b14.*b12.*b35+b11.*b23.*b44.*b25-b12.*b12.*b34.*b45+b14.*b12.*b34.*b25-b11.*b23.*b24.*b45+b23.*b24.*b14.*b15+b11.*b22.*b34.*b45+b44.*b12.*b12.*b35)./d;
ib44=(-b23.*b13.*b15.*b25+b23.*b13.*b55.*b12-b23.*b15.*b35.*b12+b23.*b11.*b35.*b25+b23.*b15.*b23.*b15-b23.*b55.*b11.*b23-b13.*b55.*b22.*b13-b13.*b35.*b25.*b12+b13.*b15.*b22.*b35+b13.*b13.*b25.*b25-b11.*b33.*b25.*b25-b15.*b22.*b33.*b15+b15.*b33.*b25.*b12+b55.*b11.*b22.*b33+b15.*b33.*b25.*b12+b55.*b23.*b12.*b13-b33.*b12.*b55.*b12+b35.*b12.*b35.*b12+b35.*b25.*b11.*b23-b11.*b35.*b22.*b35-b12.*b13.*b35.*b25+b15.*b35.*b22.*b13-b13.*b25.*b23.*b15-b15.*b35.*b23.*b12)./d;
ib45=(b24.*b23.*b13.*b15-b11.*b24.*b23.*b35-b13.*b12.*b23.*b45-b23.*b23.*b14.*b15+b14.*b12.*b23.*b35+b11.*b23.*b23.*b45-b13.*b13.*b24.*b25-b33.*b24.*b12.*b15+b11.*b33.*b24.*b25+b24.*b12.*b13.*b35-b22.*b34.*b13.*b15+b22.*b13.*b13.*b45+b34.*b13.*b12.*b25-b34.*b12.*b12.*b35+b22.*b33.*b14.*b15+b34.*b23.*b12.*b15-b11.*b22.*b33.*b45+b14.*b13.*b23.*b25+b33.*b12.*b12.*b45-b11.*b34.*b23.*b25+b11.*b22.*b34.*b35-b23.*b12.*b13.*b45-b33.*b14.*b12.*b25-b22.*b14.*b13.*b35)./d;
ib55=-(-b11.*b22.*b33.*b44+b11.*b22.*b34.*b34-b11.*b34.*b23.*b24+b11.*b33.*b24.*b24-b11.*b24.*b23.*b34+b11.*b23.*b23.*b44+b22.*b13.*b13.*b44-b22.*b34.*b13.*b14-b22.*b14.*b13.*b34+b22.*b33.*b14.*b14+b14.*b13.*b23.*b24+b14.*b12.*b23.*b34-b34.*b12.*b12.*b34+b34.*b13.*b12.*b24-b23.*b23.*b14.*b14-b33.*b24.*b12.*b14-b33.*b14.*b12.*b24+b33.*b12.*b12.*b44-b13.*b12.*b23.*b44-b23.*b12.*b13.*b44-b13.*b13.*b24.*b24+b24.*b23.*b13.*b14+b34.*b23.*b12.*b14+b24.*b12.*b13.*b34)./d;
% y project onto B'
py1 = sum(col1.*y,1);
py2 = sum(col2.*y,1);
py3 = sum(col3.*y,1);
py4 = sum(col4.*y,1);
py5 = sum(col5.*y,1);
% calculate x
x(1,:) = sum(ib11.*py1 + ib12.*py2 + ib13.*py3 + ib14.*py4 + ib15.*py5,1);
x(2,:) = sum(ib12.*py1 + ib22.*py2 + ib23.*py3 + ib24.*py4 + ib25.*py5,1);
x(3,:) = sum(ib13.*py1 + ib23.*py2 + ib33.*py3 + ib34.*py4 + ib35.*py5,1);
x(4,:) = sum(ib14.*py1 + ib24.*py2 + ib34.*py3 + ib44.*py4 + ib45.*py5,1);
x(5,:) = sum(ib15.*py1 + ib25.*py2 + ib35.*py3 + ib45.*py4 + ib55.*py5,1);
