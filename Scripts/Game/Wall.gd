extends StaticBody2D

func hit(node, _damage:float = 0):
	if node.is_in_group('Ball'):
		$'HitSound'.play()