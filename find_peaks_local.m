function [f, t] = find_peaks_local(P, thresh)
    mask = (P > thresh); [r, c] = size(P); picos = false(r, c);
    picos(2:end-1, 2:end-1) = mask(2:end-1, 2:end-1) & P(2:end-1, 2:end-1) > P(1:end-2, 2:end-1) & ...
        P(2:end-1, 2:end-1) > P(3:end, 2:end-1) & P(2:end-1, 2:end-1) > P(2:end-1, 1:end-2) & P(2:end-1, 2:end-1) > P(2:end-1, 3:end);
    [f, t] = find(picos);
end