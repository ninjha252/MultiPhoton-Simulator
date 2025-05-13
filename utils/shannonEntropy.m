function h = shannonEntropy(Q)
    % h is Shannon entropy function
    if Q == 0 || Q == 1
        % Entropy function is undefined for 0 and 1
        h = 0;
    else
        h = -Q * log2(Q) - (1 - Q) * log2(1 - Q);
    end
end

