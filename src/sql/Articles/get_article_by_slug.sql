SELECT
    a.slug AS slug,
    a.title AS title,
    a.description AS description,
    a.created_at AS created_at,
    a.updated_at AS updated_at,
    a.favorited AS favorited,
    (SELECT COUNT(*) FROM user_favorites uf WHERE uf.article_id = a.article_id) AS favorites_count,
    u.username AS author_username,
    u.bio AS author_bio,
    u.image_url AS author_image_url,
    u.following AS author_following,
    string_agg(t.name, ',') AS comma_separated_tags
    a.body AS body,
FROM
    articles a
LEFT JOIN
    users u ON a.author_id = u.user_id
LEFT JOIN
    article_tags at ON a.article_id = at.article_id
LEFT JOIN
    tags t ON at.tag_id = t.tag_id
WHERE
    a.slug = $1
GROUP BY
    a.article_id, u.user_id
