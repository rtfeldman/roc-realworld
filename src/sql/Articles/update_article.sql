UPDATE articles SET title = $1, description = $2, body = $3, updated_at = NOW()
WHERE slug = $4 AND author_id = $5 RETURNING *
