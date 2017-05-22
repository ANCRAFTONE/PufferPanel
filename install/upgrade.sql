USE pufferpanel;

SET FOREIGN_KEY_CHECKS = 0;

DROP EVENT IF EXISTS oauthTokenCleaner;

DELETE FROM oauth_clients
WHERE id NOT IN (
  SELECT * FROM (SELECT MAX(id) FROM oauth_clients GROUP BY client_id) d
);

ALTER TABLE account_change DROP FOREIGN KEY FK_account_change_users;
ALTER TABLE nodes DROP FOREIGN KEY FK_nodes_locations;
ALTER TABLE actions_log DROP FOREIGN KEY FK_actions_log_users;
ALTER TABLE servers DROP FOREIGN KEY FK_servers_nodes;
ALTER TABLE servers DROP FOREIGN KEY FK_servers_users;
ALTER TABLE permissions DROP FOREIGN KEY FK_permissions_servers;
ALTER TABLE permissions DROP FOREIGN KEY FK_permissions_users;
ALTER TABLE subusers DROP FOREIGN KEY FK_subusers_user;
ALTER TABLE subusers DROP FOREIGN KEY FK_subusers_server;
ALTER TABLE oauth_access_tokens DROP FOREIGN KEY FK_oauth_access_tokens_oauth_clients;

RENAME TABLE
    acp_settings TO backup_acp_settings,
    locations TO backup_locations,
    users TO backup_users,
    account_change TO backup_account_change,
    nodes TO backup_nodes,
    autodeploy TO backup_autodeploy,
    actions_log TO backup_actions_log,
    servers TO backup_servers,
    permissions TO backup_permissions,
    subusers TO backup_subusers,
    oauth_clients TO backup_oauth_clients,
    oauth_access_tokens TO backup_oauth_access_tokens
;

CREATE TABLE `acp_settings` (
  `id` mediumint(8) unsigned NOT NULL AUTO_INCREMENT,
  `setting_ref` varchar(25) NOT NULL,
  `setting_val` text,
  PRIMARY KEY (`id`),
  UNIQUE KEY `setting_ref_unique` (`setting_ref`)
);

CREATE TABLE `locations` (
  `id` mediumint(8) unsigned NOT NULL AUTO_INCREMENT,
  `short` varchar(10) NOT NULL,
  `long` varchar(500) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `short_unique` (`short`)
);

CREATE TABLE `users` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `uuid` char(36) NOT NULL,
  `username` varchar(50) NOT NULL,
  `email` varchar(255) NOT NULL,
  `password` text,
  `language` varchar(10) NOT NULL DEFAULT 'en_US',
  `register_time` int(15) unsigned NOT NULL,
  `session_id` char(12),
  `session_ip` varchar(50),
  `root_admin` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `notify_login_s` tinyint(1) unsigned NOT NULL DEFAULT '1',
  `notify_login_f` tinyint(1) unsigned NOT NULL DEFAULT '1',
  `use_totp` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `totp_secret` char(16),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uuid_unique` (`uuid`),
  UNIQUE KEY `email_unique` (`email`),
  UNIQUE KEY `username` (`username`)
);

CREATE TABLE `account_change` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned NOT NULL,
  `type` varchar(50) NOT NULL DEFAULT '',
  `content` mediumtext NOT NULL,
  `key` mediumtext NOT NULL,
  `time` int(15) unsigned NOT NULL,
  `verified` tinyint(1) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `FK_account_change_users` (`user_id`),
  CONSTRAINT `FK_account_change_users` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
);

CREATE TABLE `nodes` (
  `id` mediumint(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(15) NOT NULL,
  `location` mediumint(8) unsigned NOT NULL,
  `allocate_memory` mediumint(8) unsigned NOT NULL,
  `allocate_disk` int(10) unsigned NOT NULL,
  `fqdn` varchar(255) NOT NULL,
  `ip` varchar(45) NOT NULL,
  `daemon_secret` char(36) NOT NULL,
  `daemon_listen` smallint(5) unsigned DEFAULT '5656',
  `daemon_sftp` smallint(5) unsigned DEFAULT '5657',
  `ips` mediumtext NOT NULL,
  `ports` mediumtext NOT NULL,
  `public` tinyint(1) unsigned NOT NULL DEFAULT '1',
  `docker` tinyint(1) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`),
  KEY `FK_nodes_locations` (`location`),
  CONSTRAINT `FK_nodes_locations` FOREIGN KEY (`location`) REFERENCES `locations` (`id`)
);

CREATE TABLE `autodeploy` (
  `id` mediumint(10) unsigned NOT NULL AUTO_INCREMENT,
  `node` mediumint(10) unsigned NOT NULL,
  `code` char(36) NOT NULL,
  `expires` int(10) unsigned NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `FK_autodeploy_nodes` FOREIGN KEY (`node`) REFERENCES `nodes` (`id`) ON DELETE CASCADE
);

CREATE TABLE `actions_log` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `priority` tinyint(1) NOT NULL,
  `viewable` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `user` int(10) unsigned,
  `time` int(15) unsigned NOT NULL,
  `ip` varchar(100) NOT NULL,
  `url` text NOT NULL,
  `action` varchar(100) NOT NULL,
  `desc` mediumtext NOT NULL,
  PRIMARY KEY (`id`),
  KEY `FK_actions_log_users` (`user`),
  CONSTRAINT `FK_actions_log_users` FOREIGN KEY (`user`) REFERENCES `users` (`id`)
);

CREATE TABLE `servers` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `hash` char(36) NOT NULL,
  `daemon_secret` char(36) NOT NULL,
  `node` mediumint(8) unsigned NOT NULL,
  `name` varchar(200) NOT NULL,
  `active` tinyint(1) unsigned NOT NULL DEFAULT '1',
  `owner_id` int(10) unsigned NOT NULL,
  `date_added` int(10) unsigned NOT NULL,
  PRIMARY KEY (`id`),
  KEY `FK_servers_users` (`owner_id`),
  KEY `FK_servers_nodes` (`node`),
  CONSTRAINT `FK_servers_nodes` FOREIGN KEY (`node`) REFERENCES `nodes` (`id`),
  CONSTRAINT `FK_servers_users` FOREIGN KEY (`owner_id`) REFERENCES `users` (`id`)
);

CREATE TABLE `permissions` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `user` int(10) unsigned NOT NULL,
  `server` int(10) unsigned NOT NULL,
  `permission` varchar(200) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `FK_permissions_users` (`user`),
  KEY `FK_permissions_servers` (`server`),
  CONSTRAINT `FK_permissions_servers` FOREIGN KEY (`server`) REFERENCES `servers` (`id`) ON DELETE CASCADE,
  CONSTRAINT `FK_permissions_users` FOREIGN KEY (`user`) REFERENCES `users` (`id`) ON DELETE CASCADE
);

CREATE TABLE `subusers` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `user` int(10) unsigned NOT NULL,
  `server` int(10) unsigned NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_server_key` (`user`,`server`),
  KEY `FK_subusers_server` (`server`),
  CONSTRAINT `FK_subusers_server` FOREIGN KEY (`server`) REFERENCES `servers` (`id`) ON DELETE CASCADE,
  CONSTRAINT `FK_subusers_user` FOREIGN KEY (`user`) REFERENCES `users` (`id`) ON DELETE CASCADE
);

CREATE TABLE `oauth_clients` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `client_id` char(16) NOT NULL,
  `client_secret` char(64) NOT NULL,
  `user_id` int(10) unsigned,
  `server_id` int(10) unsigned,
  `scopes` varchar(1000) NOT NULL DEFAULT '',
  `name` varchar(128) NOT NULL,
  `description` varchar(1024) NOT NULL DEFAULT 'No description',
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_name_user_server` (`server_id`,`user_id`,`client_id`),
  KEY `FK_oauth_clients_users` (`user_id`),
  KEY `FK_oauth_clients_servers` (`server_id`),
  KEY `client_id` (`client_id`),
  CONSTRAINT `FK_oauth_clients_servers` FOREIGN KEY (`server_id`) REFERENCES `servers` (`id`) ON DELETE CASCADE,
  CONSTRAINT `FK_oauth_clients_users` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
);

CREATE TABLE `oauth_access_tokens` (
  `access_token` char(128) NOT NULL,
  `oauthClientId` int(10) unsigned NOT NULL,
  `expiretime` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `scopes` varchar(1000) NOT NULL DEFAULT '',
  PRIMARY KEY (`access_token`),
  UNIQUE KEY `access_token` (`access_token`),
  KEY `FK_oauth_access_tokens_oauth_clients` (`oauthClientId`),
  CONSTRAINT `FK_oauth_access_tokens_oauth_clients` FOREIGN KEY (`oauthClientId`) REFERENCES `oauth_clients` (`id`) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS `_meta` (
  `metaId` INT(11) NOT NULL AUTO_INCREMENT,
  `metaKey` VARCHAR(20) NOT NULL,
  `metaValue` VARCHAR(200) NOT NULL,
  PRIMARY KEY (`metaId`),
  UNIQUE INDEX `UK_metaKey` (`metaKey`)
);

INSERT INTO _meta (metaKey, metaValue) VALUES
  ('version', 'v1.1.2'),
  ('originalVersion', 'unknown'),
  ('installDate', 'unknown'),
  ('updateDate', CURRENT_TIMESTAMP);

INSERT INTO acp_settings
    SELECT * FROM backup_acp_settings;

INSERT INTO locations
    SELECT * FROM backup_locations;

INSERT INTO users
    SELECT * FROM backup_users;

INSERT INTO account_change
    SELECT * FROM backup_account_change;

INSERT INTO nodes
    SELECT * FROM backup_nodes;

INSERT INTO autodeploy
    SELECT * FROM backup_autodeploy;

INSERT INTO actions_log
    SELECT * FROM backup_actions_log;

INSERT INTO servers
    SELECT * FROM backup_servers;

INSERT INTO permissions
    SELECT * FROM backup_permissions;

INSERT INTO subusers
    SELECT id, user, server FROM backup_subusers;

INSERT INTO oauth_clients
    SELECT * FROM backup_oauth_clients;

INSERT INTO oauth_access_tokens
    SELECT * FROM backup_oauth_access_tokens;

DELIMITER //
CREATE EVENT `oauthTokenCleaner` ON SCHEDULE EVERY 12 HOUR ON COMPLETION PRESERVE ENABLE COMMENT 'Cleans up the oauth access tokens' DO DELETE FROM oauth_access_tokens WHERE expireTime < NOW()//
DELIMITER ;

DELIMITER //
CREATE TRIGGER `subusers_before_delete` BEFORE DELETE ON `subusers` FOR EACH ROW DELETE FROM oauth_clients WHERE oauth_clients.user_id = OLD.user AND oauth_clients.server_id = OLD.server//
DELIMITER ;

SET FOREIGN_KEY_CHECKS = 1;
