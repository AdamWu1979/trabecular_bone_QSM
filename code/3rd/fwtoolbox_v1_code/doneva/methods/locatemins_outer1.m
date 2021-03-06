function maps = locatemins_outer1(image,algoParams,dTE,f_wf)
% maps = locatemins_outer(image,algoParams,dTE,f_wf)
% Locate all possible field map values for 3 point measurement
%
% Inputs:
%
% image: three echo images 
% dTE: echo time spacing
% f_wf: chemical shift between water and fat in Hz
% 
% Outputs: possible field map values


[sx, sy, no_echoes] = size(image);  
% Check input data
if no_echoes ~= 3
   disp('ERROR: the reconstruction supports 3 point measurements only')
   maps = [];
  return;
end
    

maps = 0*ones(sx, sy, 2); 

TE        = (0:no_echoes-1)*dTE;


% consider multi-peak fat model

BB = [];

for i = 1:length(algoParams.species)
    relAmps = algoParams.species(i).relAmps;   
    temp = zeros(length(relAmps),length(algoParams.species));
    temp(:,i) = relAmps(:);
    BB = [BB;temp];
end

% Compute model matrix
AA = zeros(no_echoes,length(f_wf));

for j = 1:no_echoes
    for k = 1:length(f_wf)
        AA(j,k) = exp(1i*2*pi*f_wf(k)*TE(j));
    end
end


if length(f_wf) > 2
AA = AA*BB;        
end

x    = AA*pinv(AA'*AA)*AA' - eye(no_echoes);

for i = 1: sx
    for j = 1:sy
        
        signal = image(i,j,:);
        signal = signal(:);
        
        temp = locatemins(signal,dTE, x);
        for k = 1:length(temp)
            maps(i,j,k) = temp(k);
        end
        
    end
end


function mins = locatemins(s,deltaTE, x)

% find  polynom coefficients
label = 0;
delta = 2;

a1 = (sum(x(:,2)*s(2).*conj(x(:,1)*s(1)))  + sum(x(:,3)*s(3).*conj(x(:,2)*s(2))));
%a2 = conj(a1);

b1 = (sum(x(:,3)*s(3).*conj(x(:,1)*s(1))));
%b2 = conj(b1);

% Convert to complex polynomial and find roots 

aa1 = (imag(a1)   + sqrt(-1)*real(a1));
aa2 = (imag(a1)   - sqrt(-1)*real(a1));
bb1 = 2*(imag(b1) + sqrt(-1)*real(b1));
bb2 = 2*(imag(b1) - sqrt(-1)*real(b1));


coeff = [bb2 aa2 0 aa1 bb1];

temp   = roots(coeff);

% critical points
truesol = abs(abs(temp)-1)<0.001;
points = angle(temp(truesol))/(-2*pi*deltaTE);


% determine if maximum or minimum
% use neighbourhood compute J(x +/- delta)


if numel(points) >0
    
for i = 1:length(points)    
    
neigh =  [ - delta, 0, delta] + points(i);

neigh = -2*pi*deltaTE*neigh;
J = real(a1)*cos(neigh) - imag(a1)*sin(neigh) + real(b1)*cos(2*neigh) - imag(b1)*sin(2*neigh);

if (J(2) < J(1)) && (J(2) < J(3))    
label(i) = 1;
end

end

mins = points((label>0));


else
    mins = 0;
end






