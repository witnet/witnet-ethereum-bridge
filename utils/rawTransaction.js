module.exports = function (json, r, s, gasprice, gaslimit) {
  return {
    gasPrice: gasprice,
    value: 0,
    data: json.bytecode,
    gasLimit: gaslimit,
    v: 27,
    r: r,
    s: s,
  }
}
