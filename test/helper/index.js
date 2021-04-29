module.exports = {
    expectOutput: (input, fee, liq) => {
        const inputWithFee = input * BigInt(1e9 - fee)
        const numerator = inputWithFee * liq[1]
        const denominator = liq[0] * BigInt(1e9) + inputWithFee

        return numerator / denominator
    }
}
