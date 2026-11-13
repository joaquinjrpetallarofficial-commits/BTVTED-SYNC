-- =====================================================================
-- CCD BTVTeD Sync - Student Research Repository
-- Database schema + seed data (MySQL / MariaDB compatible)
-- Derived from the data model used in the HTML app (users, submissions,
-- approved papers, view counter).
-- =====================================================================

CREATE DATABASE IF NOT EXISTS ccd_btvted_sync
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE ccd_btvted_sync;

-- ---------- Tables ----------
CREATE TABLE IF NOT EXISTS users (
  user_id        INT AUTO_INCREMENT PRIMARY KEY,
  username       VARCHAR(50)  NOT NULL UNIQUE,
  password_hash  VARCHAR(255) NOT NULL,          -- store a bcrypt/argon2 hash, never plain text
  full_name      VARCHAR(120) NOT NULL,
  role           ENUM('admin','student') NOT NULL DEFAULT 'student',
  created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS categories (
  category_id    INT AUTO_INCREMENT PRIMARY KEY,
  name           VARCHAR(100) NOT NULL UNIQUE
);

-- One table for everything: seed papers, pending, approved and rejected submissions
CREATE TABLE IF NOT EXISTS research_papers (
  paper_id       INT AUTO_INCREMENT PRIMARY KEY,
  title          VARCHAR(300) NOT NULL,
  authors        TEXT         NOT NULL,
  abstract       TEXT         NOT NULL,
  pub_year       SMALLINT     NOT NULL,
  category_id    INT          NOT NULL,
  citation       TEXT NULL,
  file_name      VARCHAR(255) NULL,
  file_path      VARCHAR(500) NULL,               -- PDF stored on disk/cloud (max 2 MB in the app)
  submitted_by   INT NULL,                        -- NULL = CCD seed record
  status         ENUM('pending','approved','rejected') NOT NULL DEFAULT 'pending',
  admin_note     VARCHAR(500) NULL,
  submitted_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  approved_by    INT NULL,
  approved_at    DATETIME NULL,
  defense_date   DATE NULL,
  FOREIGN KEY (category_id)  REFERENCES categories(category_id),
  FOREIGN KEY (submitted_by) REFERENCES users(user_id),
  FOREIGN KEY (approved_by)  REFERENCES users(user_id),
  INDEX idx_status (status),
  INDEX idx_year (pub_year),
  FULLTEXT KEY ft_search (title, authors, abstract)
);

-- One row per view (counted once per user per paper per session in the app)
CREATE TABLE IF NOT EXISTS paper_views (
  view_id    BIGINT AUTO_INCREMENT PRIMARY KEY,
  paper_id   INT NOT NULL,
  user_id    INT NOT NULL,
  viewed_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (paper_id) REFERENCES research_papers(paper_id) ON DELETE CASCADE,
  FOREIGN KEY (user_id)  REFERENCES users(user_id) ON DELETE CASCADE,
  INDEX idx_paper (paper_id)
);

-- ---------- Seed data ----------
INSERT INTO categories (name) VALUES
  ('Computer Science'),
  ('Agriculture'),
  ('Environment & Disaster Management');

-- Replace the placeholder hashes with real bcrypt/argon2 hashes before use.
INSERT INTO users (username, password_hash, full_name, role) VALUES
  ('admin',   '<REPLACE_WITH_HASH>', 'Admin',   'admin'),
  ('student', '<REPLACE_WITH_HASH>', 'Student', 'student');

INSERT INTO research_papers (title, authors, abstract, pub_year, category_id, citation, status) VALUES
  ('Automated Drainage Cleaner with Water Level Monitoring and SMS Flood Alert System',
   'Silongan, M. J. A., Lorenzo, C. S. B., Gamus, E. D. C., Mariposque, C. J. A., Romano, R. C., Masangya, R. A., Maguana, G. E., & Pene, J. A.',
   'This project study designs and develops an automated drainage cleaner to clear blockages, combined with real-time water level monitoring and a GSM-based SMS flood alert system to mitigate urban flooding and protect vulnerable communities in Davao City.',
   2025,
   (SELECT category_id FROM categories WHERE name = 'Environment & Disaster Management'),
   'Silongan, M. J. A., et al. (2025). Automated Drainage Cleaner with Water Level Monitoring and SMS Flood Alert System. City College of Davao, Bachelor of Technical Vocational Teacher Education.',
   'approved'),
  ('Smart Flood Alert System',
   'Quibol, P. J. B., Gamboa, J. A. B., Demeterio, B. M. J., Escobarte, L. A. M., Felizarta, R. I. A., Bacurnay, C. P., Batitay, M. S., & Teofilo, J. R.',
   'An affordable, community-based early warning system designed to detect rising water levels and identify human presence in danger zones using PIR motion detection, audible alarms, and SMS notifications to prevent casualties during flash floods.',
   2025,
   (SELECT category_id FROM categories WHERE name = 'Environment & Disaster Management'),
   'Quibol, P. J. B., et al. (2025). Smart Flood Alert System. City College of Davao, Bachelor of Technical Vocational Teacher Education.',
   'approved'),
  ('Smart Ventilation Control System for Chicken Factories',
   'Perez, C. J., Petallar, J. P., Quicoy, A. M., Autida, R. M., Drama, A., Baldovi, J., & Onio, G.',
   'An IoT-driven agricultural automation project aimed at reducing heat stress and managing air quality (such as ammonia and humidity levels) in poultry housing through automated temperature monitoring and ventilation control.',
   2025,
   (SELECT category_id FROM categories WHERE name = 'Agriculture'),
   'Perez, C. J., et al. (2025). Smart Ventilation Control System for Chicken Factories. City College of Davao, Bachelor of Technical Vocational Teacher Education.',
   'approved'),
  ('SmartFish: A Sustainable and Innovative System for Real-Time Water Level Monitoring, Smart Filtration, and Automated Fish Farm Maintenance',
   'Batucan, M. F. V., Magayo, L. L., Turnos, D. N. L., Pagat, A. K. R., Castillo, M. E., Malanas, D. F. A., Talay, R. F., Corlit, R. R. A., & Flores, H. C.',
   'A sustainable aquaculture solution integrating automated water level sensing, smart filtration/recycling mechanisms, and automated feeding to enhance fish yield, reduce water contamination, and modernize traditional fish farming operations.',
   2025,
   (SELECT category_id FROM categories WHERE name = 'Agriculture'),
   'Batucan, M. F. V., et al. (2025). SmartFish: A Sustainable and Innovative System for Real-Time Water Level Monitoring, Smart Filtration, and Automated Fish Farm Maintenance. City College of Davao, Bachelor of Technical Vocational Teacher Education.',
   'approved'),
  ('pH Level Monitoring System and Drainer for Aquaculture',
   'Coscos, K. D. M. C., Echavez, C. A. A., Guiang, G. A. O., Concellado, C. J. R., Bermudez, G. P., Alfafara, C. A., Fulguerinas, J. H., & Elivera, C. R.',
   'An IoT-based system for fish farms that continuously measures pond water pH with a sensor controlled by an Arduino Uno and shows the reading on an LCD. When pH becomes unsafe, a SIM800L GSM module sends SMS alerts to the owner, and a servo motor opens a gate to drain the water, closing it again once pH returns to normal. The study tests real-time monitoring, sensor accuracy and drainage effectiveness as a low-cost alternative to manual pH testing for small to medium-sized fish farms.',
   2025,
   (SELECT category_id FROM categories WHERE name = 'Agriculture'),
   'Coscos, K. D. M. C., Echavez, C. A. A., Guiang, G. A. O., Concellado, C. J. R., Bermudez, G. P., Alfafara, C. A., Fulguerinas, J. H., & Elivera, C. R. (2025). pH Level Monitoring System and Drainer for Aquaculture. City College of Davao, Bachelor of Technical Vocational Teacher Education.',
   'approved');

-- ---------- Queries matching the app's features ----------

-- Repository search + category filter + year sort (newest first)
SELECT p.paper_id, p.title, p.authors, p.pub_year, c.name AS category, p.abstract
FROM research_papers p
JOIN categories c ON c.category_id = p.category_id
WHERE p.status = 'approved'
  AND (p.title LIKE CONCAT('%', :search, '%')
    OR p.authors LIKE CONCAT('%', :search, '%')
    OR p.abstract LIKE CONCAT('%', :search, '%'))
  AND (:category = 'All' OR c.name = :category)
ORDER BY p.pub_year DESC;   -- use ASC for oldest first

-- Student: my submissions
SELECT title, status, admin_note, submitted_at, file_name
FROM research_papers WHERE submitted_by = :user_id ORDER BY submitted_at DESC;

-- Admin: pending applications
SELECT p.*, u.username AS uploaded_by
FROM research_papers p JOIN users u ON u.user_id = p.submitted_by
WHERE p.status = 'pending' ORDER BY p.submitted_at DESC;

-- Admin: approve a paper
UPDATE research_papers
SET status = 'approved', approved_by = :admin_id, approved_at = NOW(),
    defense_date = :defense_date, admin_note = :note
WHERE paper_id = :paper_id;

-- Admin: reject a paper
UPDATE research_papers SET status = 'rejected', admin_note = :note WHERE paper_id = :paper_id;

-- Record a view (skip admins and the paper's own publisher in your app/code)
INSERT INTO paper_views (paper_id, user_id) VALUES (:paper_id, :user_id);

-- Admin: view counter (total views, unique viewers, last viewed)
SELECT p.title,
       COALESCE(u.username, 'CCD (seed)') AS publisher,
       COUNT(v.view_id)                   AS total_views,
       COUNT(DISTINCT v.user_id)          AS unique_viewers,
       MAX(v.viewed_at)                   AS last_viewed
FROM research_papers p
LEFT JOIN users u ON u.user_id = p.submitted_by
LEFT JOIN paper_views v ON v.paper_id = p.paper_id
WHERE p.status = 'approved'
GROUP BY p.paper_id, p.title, u.username
ORDER BY total_views DESC;