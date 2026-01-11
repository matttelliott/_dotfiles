import * as pulumi from "@pulumi/pulumi";
import * as digitalocean from "@pulumi/digitalocean";

const config = new pulumi.Config();
const sshKeyFingerprint = config.require("sshKeyFingerprint");

const droplet = new digitalocean.Droplet("debian", {
    image: "debian-12-x64",
    region: "nyc1",
    size: "s-2vcpu-4gb",
    sshKeys: [sshKeyFingerprint],
    name: "debian",
});

export const dropletIp = droplet.ipv4Address;
export const dropletId = droplet.id;
