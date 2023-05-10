How to release? Just push a new tag that ends with "ez" and let github actions build the zip and create the release.

```bash
git tag -a v2.10-ez -m 'v2.10-ez'
git push --tags
```
