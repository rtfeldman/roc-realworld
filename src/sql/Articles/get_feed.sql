SELECT a.*, u.username, u.bio, u.image_url,
    (SELECT COUNT(*) FROM user_favorites uf WHERE uf.article_id = a.id) AS favorites_count
FROM articles a
    JOIN users u ON a.author_id = u.id
WHERE a.author_id IN (SELECT followed_id FROM follows WHERE follower_id = $1)
ORDER BY a.created_at DESC
LIMIT $2
OFFSET $3
