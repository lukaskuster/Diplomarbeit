const expect = require('chai').expect;
const supertest = require('supertest');
const api = supertest('localhost:3000/v1');

describe('PUT /gateway', function () {

    const gateway = {
        imei: 'testimei1',
        name: 'Home',
        phoneNumber: '123445'
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

    beforeEach(function (done) {
        api.post('/gateway')
            .set('Accept', 'application/json')
            .auth(user.mail, user.password)
            .send(gateway)
            .expect(200 , done)
    });

    afterEach(function (done) {
        api.delete(`/gateway/${gateway.imei}`)
            .auth(user.mail, user.password)
            .send()
            .expect(200, done)
    });

    it('should return a 200 response', function (done) {
        api.put(`/gateway/${gateway.imei}`)
            .set('Accept', 'application/json')
            .auth(user.mail, user.password)
            .send(gateway)
            .expect(200, done)
    });

    it('should return a 404 response', function (done) {
        api.put(`/gateway`)
            .set('Accept', 'application/json')
            .auth(user.mail, user.password)
            .expect(404, done)
    });

    it('should return the saved data', function (done) {
        api.put(`/gateway/${gateway.imei}`)
            .set('Accept', 'application/json')
            .auth(user.mail, user.password)
            .send(gateway)
            .expect(200)
            .end(function (err, res) {
                expect(res.body).to.deep.equal(gateway);
                done()
            })
    });

    it('should return the gateway object', function (done) {
        api.put(`/gateway/${gateway.imei}`)
            .set('Accept', 'application/json')
            .auth(user.mail, user.password)
            .send(gateway)
            .expect(200)
            .end(function (err, res) {
                api.put(`/gateway/${gateway.imei}`)
                    .set('Accept', 'application/json')
                    .auth(user.mail, user.password)
                    .expect(200)
                    .end(function (err, res) {
                        expect(res.body).to.deep.equal(gateway);
                        done()
                    });
            })
    });

    it('should return a 401 response', function (done) {
        api.put(`/gateway/${gateway.imei}`)
            .set('Accept', 'application/json')
            .send()
            .expect(401)
            .end(function (err, res) {
                expect(res.body.errorCode).to.equal(10010);
                api.put(`/gateway/${gateway.imei}`)
                    .set('Accept', 'application/json')
                    .auth(user.mail, user.password)
                    .send(gateway)
                    .expect(200 , done)
            })
    });

    it('should update gateway data', function (done) {
        api.put(`/gateway/${gateway.imei}`)
            .set('Accept', 'application/json')
            .auth(user.mail, user.password)
            .send({name: 'Test'})
            .expect(200)
            .end(function (err, res) {
                expect(res.body).to.have.property('name');

                api.get(`/gateway/${gateway.imei}`)
                    .set('Accept', 'application/json')
                    .auth(user.mail, user.password)
                    .send()
                    .expect(200)
                    .end(function (err, res) {
                        expect(res.body.name).to.equal('Test');
                        done()
                    })
            })
    });
});
