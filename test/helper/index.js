module.exports = {
    expectOutput: (input, fee, liq) => {
        const inputWithFee = BigInt(input) * BigInt(1e9 - fee)
        const numerator = inputWithFee * BigInt(liq[1])
        const denominator = BigInt(liq[0]) * BigInt(1e9) + inputWithFee

        return numerator / denominator
    }
}
