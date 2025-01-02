INSERT INTO user_favorites (user_id, article_id)
SELECT $1, id FROM articles WHERE slug = $2
ON CONFLICT DO NOTHING;
