print("Creating users...");

db.createUser({
    user: "mongo",
    pwd: "mongo",
    roles: [{
        role: "readWrite",
        db: db.getName()
    }]
});

print("Users successully created!");