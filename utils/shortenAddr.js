module.exports = function (addr) {
  return addr.substring(0, 6) + ".." + addr.slice(-4)
}
