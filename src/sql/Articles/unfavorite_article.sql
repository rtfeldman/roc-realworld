DELETE FROM user_favorites
WHERE user_id = $1 AND article_id = (SELECT id FROM articles WHERE slug = $2);
