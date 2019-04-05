const expect = require('chai').expect;
const supertest = require('supertest');
const api = supertest('localhost:3000/v1');

describe('POST /gateway', function () {

    const gateway = {
        imei: 'testimei1'
    };

    const user = {
        mail: 'mail@test.com',
        password: 'test',
        firstName: 'Nice',
        lastName: 'Tester'
    };


    before(function (done) {
        api.post('/user')
            .set('Accept', 'application/json')
            .send(user)
            .end(function (err, res) {
                expect(res.status).to.equal(200);
                done()
            });
    });

    after(function (done) {
        api.delete(`/user`)
            .auth(user.mail, user.password)
            .send()
            .expect(200, done)
    });

    afterEach(function (done) {
        api.delete(`/gateway/${gateway.imei}`)
            .auth(user.mail, user.password)
            .send()
            .expect(200, done)
    });


    it('should return a 200 response', function (done) {
        api.post('/gateway')
            .set('Accept', 'application/json')
            .auth(user.mail, user.password)
            .send(gateway)
            .expect(200 , done)
    });

    it('should return imei', function (done) {
        api.post('/gateway')
            .set('Accept', 'application/json')
            .auth(user.mail, user.password)
            .send(gateway)
            .expect(200)
            .end(function (err, res) {
                expect(res.body).to.have.property('imei');
                done()
            })
    });

    it('should return a 409 response', function (done) {
        api.post('/gateway')
            .set('Accept', 'application/json')
            .auth(user.mail, user.password)
            .send(gateway)
            .expect(200)
            .end(function (err, res) {
                api.post('/gateway')
                    .set('Accept', 'application/json')
                    .auth(user.mail, user.password)
                    .send(gateway)
                    .expect(409)
                    .end(function (err, res) {
                        expect(res.body.errorCode).to.equal(10001);
                        done();
                    })
            });
    });

    it('should return a 403 response', function (done) {
        api.post('/gateway')
            .set('Accept', 'application/json')
            .auth(user.mail, user.password)
            .send()
            .expect(403)
            .end(function (err, res) {
                expect(res.body.errorCode).to.equal(10000);
                api.post('/gateway')
                    .set('Accept', 'application/json')
                    .auth(user.mail, user.password)
                    .send(gateway)
                    .expect(200 , done)
            })
    });

    it('should return a 401 response', function (done) {
        api.post('/gateway')
            .set('Accept', 'application/json')
            .send()
            .expect(401)
            .end(function (err, res) {
                expect(res.body.errorCode).to.equal(10010);
                api.post('/gateway')
                    .set('Accept', 'application/json')
                    .auth(user.mail, user.password)
                    .send(gateway)
                    .expect(200 , done)
            })
    });
});
