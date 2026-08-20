const { proxy } = require('./_lib.js');
module.exports = (req, res) => proxy(req, res, '/webhook/chatbot');
