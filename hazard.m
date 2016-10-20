function val = hazard (name, X, A, B)
    val = pdf (name, X, A, B) ./ (1 - cdf(name, X, A, B));
end