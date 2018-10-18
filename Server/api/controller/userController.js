module.exports = {
    getUser : function(req, res){
        return res.json(res.locals.user);
    }
};